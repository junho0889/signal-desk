import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../src/app_scope.dart';
import '../../src/signal_desk_localizations.dart';
import 'premium_tokens.dart';

class SignalDeskShell extends StatelessWidget {
  const SignalDeskShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.contextRail,
    this.primaryAction,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final Widget? contextRail;
  final Widget? primaryAction;

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
    final l10n = SignalDeskLocalizations.of(context);
    final appScope = SignalDeskAppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            onPressed: appScope.toggleLocale,
            child: Text(appScope.isKorean ? 'EN' : 'KO'),
          ),
          const SizedBox(width: SignalDeskSpacing.s8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (contextRail != null) contextRail!,
            Expanded(child: child),
            if (primaryAction != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  SignalDeskSpacing.s16,
                  SignalDeskSpacing.s8,
                  SignalDeskSpacing.s16,
                  SignalDeskSpacing.s12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: primaryAction!,
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexForRoute(currentRoute),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onNavTap(context, index),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: l10n.homeTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.format_list_numbered),
            label: l10n.rankingTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border),
            label: l10n.watchlistTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_none),
            label: l10n.alertsTitle,
          ),
        ],
      ),
    );
  }
}
