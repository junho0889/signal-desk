import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class SignalDeskShell extends StatelessWidget {
  const SignalDeskShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
  });

  final String title;
  final String currentRoute;
  final Widget child;

  int _indexForRoute(String route) {
    switch (route) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.ranking:
        return 1;
      case AppRoutes.watchlist:
        return 2;
      case AppRoutes.alerts:
        return 3;
      default:
        return 0;
    }
  }

  void _onNavTap(BuildContext context, int index) {
    final targetRoute = AppRoutes.ordered[index];
    if (targetRoute == currentRoute) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexForRoute(currentRoute),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onNavTap(context, index),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_numbered), label: 'Ranking'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Watchlist'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alerts'),
        ],
      ),
    );
  }
}
