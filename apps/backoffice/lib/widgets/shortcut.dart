import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class RecordShortcuts extends StatefulWidget {
  const RecordShortcuts({required this.itemCount, required this.builder, this.onActivate, super.key});

  final int itemCount;
  final Widget Function(BuildContext context, int focusedIndex) builder;
  final ValueChanged<int>? onActivate;

  @override
  State<RecordShortcuts> createState() => _RecordShortcutsState();
}

class _RecordShortcutsState extends State<RecordShortcuts> {
  final _focusNode = FocusNode();
  int _index = 0;

  void _move(int index) {
    if (widget.itemCount == 0) return;
    setState(() => _index = index.clamp(0, widget.itemCount - 1));
  }

  @override
  void didUpdateWidget(covariant RecordShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.itemCount) _index = widget.itemCount - 1;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focusNode,
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          _move(_index + 1);
        case LogicalKeyboardKey.arrowUp:
          _move(_index - 1);
        case LogicalKeyboardKey.home:
          _move(0);
        case LogicalKeyboardKey.end:
          _move(widget.itemCount - 1);
        case LogicalKeyboardKey.enter:
          widget.onActivate?.call(_index);
        default:
          return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    },
    child: Builder(builder: (context) {
      final focused = Focus.of(context).hasFocus;
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: focused ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.builder(context, focused ? _index : -1),
      );
    }),
  );
}
