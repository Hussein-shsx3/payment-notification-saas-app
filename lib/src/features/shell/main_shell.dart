import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../support/support_screen.dart';

/// Root layout after login: Home, Support, and Settings are peers (not nested).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const barBg = Color(0xFF0B1220);
    const barBorder = Color(0xFF1E293B);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          SupportScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: barBg,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: barBorder, width: 1)),
          ),
          child: NavigationBar(
            backgroundColor: barBg,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black54,
            elevation: 0,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: const Color(0xFF06B6D4).withValues(alpha: 0.28),
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.bottomNavHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.support_agent_outlined),
                selectedIcon: const Icon(Icons.support_agent_rounded),
                label: l10n.supportNav,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: l10n.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
