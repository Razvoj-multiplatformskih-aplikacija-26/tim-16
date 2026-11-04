import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../text/order_presentation.dart';
import '../widgets/order_detail_panel.dart';


const double _tableBreakpoint = 800;
const double _detailPanelWidth = 380;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {

  OrderId? _selectedId;

  final FocusNode _focusNode = FocusNode(debugLabel: 'orders');
  bool _hasFocus = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _select(Order order) {
    setState(() => _selectedId = order.id);
    _focusNode.requestFocus();
  }

  void _clearSelection() => setState(() => _selectedId = null);

  KeyEventResult _onKey(KeyEvent event, List<Order> orders, int selectedIndex) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (orders.isEmpty) return KeyEventResult.ignored;

    void moveTo(int index) =>
        _select(orders[index.clamp(0, orders.length - 1)]);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        moveTo(selectedIndex < 0 ? 0 : selectedIndex + 1);
      case LogicalKeyboardKey.arrowUp:
        moveTo(selectedIndex < 0 ? 0 : selectedIndex - 1);
      case LogicalKeyboardKey.home:
        moveTo(0);
      case LogicalKeyboardKey.end:
        moveTo(orders.length - 1);
      case LogicalKeyboardKey.enter:
        if (selectedIndex < 0) return KeyEventResult.ignored;
        _changeStatus(orders[selectedIndex]);
      case LogicalKeyboardKey.escape:
        if (selectedIndex < 0) return KeyEventResult.ignored;
        _clearSelection();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        if (state is ShopLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ShopError) return Center(child: Text(state.message));
        if (state is! ShopLoaded) {
          return const Center(child: Text('Nema porudžbina.'));
        }

        final orders = state.orders;
        final selectedIndex = orders.indexWhere((o) => o.id == _selectedId);
        final selected = selectedIndex < 0 ? null : orders[selectedIndex];
        final pending = orders.where((o) => o.status is Pending).length;
        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Porudžbine',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('${orders.length} ukupno · $pending na čekanju'),
            const Text(
              'Tastatura: ↑/↓ kretanje · Home/End prvi ili poslednji · '
                  'Enter promena statusa · Esc zatvara detalj',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Focus(
                focusNode: _focusNode,
                autofocus: true,
                onFocusChange: (value) => setState(() => _hasFocus = value),
                onKeyEvent: (_, event) =>
                    _onKey(event, orders, selectedIndex),
                child: DecoratedBox(
                  // Vidljiv fokus: okvir oko radne površine.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasFocus ? scheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                    constraints.maxWidth >= _tableBreakpoint
                        ? _wideLayout(orders, selected)
                        : _narrowLayout(orders, selected),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  // ---------------------------------------------------------------- široko

  Widget _wideLayout(List<Order> orders, Order? selected) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _OrdersTable(
              orders: orders,
              selectedId: selected?.id,
              // Kad je panel otvoren, manje kolona stane u tabelu.
              compact: selected != null,
              onSelect: _select,
            ),
          ),
          if (selected != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: _detailPanelWidth,
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: OrderDetailPanel(
                    order: selected,
                    onChangeStatus: () => _changeStatus(selected),
                    onClose: _clearSelection,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- usko

  Widget _narrowLayout(List<Order> orders, Order? selected) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isSelected = order.id == selected?.id;
        return Card(
          color: isSelected ? scheme.primaryContainer : null,
          child: Column(
            children: [
              ListTile(
                selected: isSelected,
                title: Text('${order.id.value} · ${order.total} RSD'),
                subtitle: Text(
                  '${formatDateTime(order.createdAt)}\n${linesSummary(order)}',
                ),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(order.status.label),
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => _select(order),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: OrderDetailPanel(
                    order: order,
                    onChangeStatus: () => _changeStatus(order),
                    onClose: _clearSelection,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------- promena stanja

  Future<void> _changeStatus(Order order) async {
    final choices = nextStatuses(order.status);
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Za ovu porudžbinu nema dozvoljene promene statusa.'),
        ),
      );
      return;
    }
    final selected = await showDialog<OrderStatus>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Promeni status · ${order.id.value}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final status in choices)
              ListTile(
                title: Text(status.actionLabel),
                onTap: () => Navigator.pop(dialogContext, status),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Odustani'),
          ),
        ],
      ),
    );
    if (selected != null && mounted) {
      context
          .read<ShopBloc>()
          .add(ChangeOrderStatusEvent(orderId: order.id, status: selected));
    }
    if (mounted) _focusNode.requestFocus();
  }
}

// ------------------------------------------------------------------ tabela

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({
    required this.orders,
    required this.selectedId,
    required this.compact,
    required this.onSelect,
  });

  final List<Order> orders;
  final OrderId? selectedId;
  final bool compact;
  final ValueChanged<Order> onSelect;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: [
            const DataColumn(label: Text('Broj')),
            const DataColumn(label: Text('Datum')),
            if (!compact) const DataColumn(label: Text('Kupac')),
            const DataColumn(label: Text('Proizvod')),
            const DataColumn(label: Text('Iznos')),
            if (!compact) const DataColumn(label: Text('Isporuka')),
            const DataColumn(label: Text('Status')),
          ],
          rows: [
            for (final order in orders)
              DataRow(
                selected: order.id == selectedId,
                onSelectChanged: (_) => onSelect(order),
                cells: [
                  DataCell(Text(order.id.value)),
                  DataCell(Text(formatDateTime(order.createdAt))),
                  if (!compact) DataCell(Text(order.buyerId.value)),
                  DataCell(Text(linesSummary(order))),
                  DataCell(Text('${order.total} RSD')),
                  if (!compact) DataCell(Text(deliveryLabel(order))),
                  DataCell(Chip(label: Text(order.status.label))),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}