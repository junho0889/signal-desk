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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: SignalDeskSpacing.s12),
            child: FilledButton.tonalIcon(
              onPressed: appScope.toggleLocale,
              icon: const Icon(Icons.language, size: 18),
              label: Text(appScope.isKorean ? 'EN' : 'KO'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: SignalDeskSpacing.s8,
                  vertical: SignalDeskSpacing.s8,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                SignalDeskPalette.shellTop,
                SignalDeskPalette.shellBottom,
              ],
            ),
          ),
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
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: primaryAction!,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexForRoute(currentRoute),
        onDestinationSelected: (index) => _onNavTap(context, index),
        height: 70,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.homeTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: l10n.rankingTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            label: l10n.watchlistTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_none),
            selectedIcon: const Icon(Icons.notifications),
            label: l10n.alertsTitle,
          ),
        ],
      ),
    );
  }
}
