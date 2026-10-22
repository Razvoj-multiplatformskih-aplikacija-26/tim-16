
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Početna',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.login_outlined),
      activeIcon: Icon(Icons.login),
      label: 'Prijava',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.app_registration_outlined),
      activeIcon: Icon(Icons.app_registration),
      label: 'Registracija',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    onTap(index);

    Widget? screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const LoginScreen();
        break;
      case 2:
        screen = const RegisterScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
    }

    if (screen != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => screen!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _navigate(context, index),
      items: _items,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 8,
    );
  }
}
