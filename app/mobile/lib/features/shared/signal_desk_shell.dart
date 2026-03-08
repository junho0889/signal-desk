import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
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
    final strings = AppLanguageScope.stringsOf(context);
    final languageController = AppLanguageScope.controllerOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          Tooltip(
            message: strings.languageToggleTooltip,
            child: TextButton(
              onPressed: languageController.toggle,
              child: Text(
                strings.languageToggleLabel,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexForRoute(currentRoute),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onNavTap(context, index),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: strings.navHome),
          BottomNavigationBarItem(icon: const Icon(Icons.format_list_numbered), label: strings.navRanking),
          BottomNavigationBarItem(icon: const Icon(Icons.bookmark_border), label: strings.navWatchlist),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_none), label: strings.navAlerts),
        ],
      ),
    );
  }
}
