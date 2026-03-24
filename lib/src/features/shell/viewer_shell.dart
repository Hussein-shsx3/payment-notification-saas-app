import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../notifications/notification_center_screen.dart';
import '../settings/settings_screen.dart';

/// Read-only session: payment notifications only + language (see [SettingsScreen.viewerMode]).
class ViewerShell extends StatefulWidget {
  const ViewerShell({super.key});

  @override
  State<ViewerShell> createState() => _ViewerShellState();
}

class _ViewerShellState extends State<ViewerShell> {
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
          NotificationCenterScreen(readOnly: true),
          SettingsScreen(viewerMode: true),
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
                icon: const Icon(Icons.notifications_outlined),
                selectedIcon: const Icon(Icons.notifications_rounded),
                label: l10n.bottomNavPayments,
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
