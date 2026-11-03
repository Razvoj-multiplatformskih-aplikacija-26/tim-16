
import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../text/domain_errors.dart';
import 'app_bottom_navigation.dart';


class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _showFeedback(BuildContext context, ShopFeedback feedback) {
    final message = switch (feedback) {
      OrderPlaced() => 'Porudžbina je poslata proizvođaču.',
      OrderCancelled() => 'Porudžbina je otkazana.',
      RuleViolated(:final error) => error.message,
      ActionFailed() => 'Radnja nije uspela. Pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShopBloc, ShopState>(
      listenWhen: (previous, current) =>
      current is ShopLoaded &&
          current.feedback != null &&
          current.feedback != (previous is ShopLoaded ? previous.feedback : null),
      listener: (context, state) {
        if (state is ShopLoaded && state.feedback != null) {
          _showFeedback(context, state.feedback!);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

