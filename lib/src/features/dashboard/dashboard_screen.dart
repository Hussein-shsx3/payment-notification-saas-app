import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import '../notifications/notification_center_screen.dart';
import '../notifications/services/android_notification_capture_service.dart';
import '../profile/profile_screen.dart';
import '../subscription/subscription_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late final AndroidNotificationCaptureService _captureService;
  bool _captureRunning = false;
  bool _hasPermission = false;
  bool _openingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureService = AndroidNotificationCaptureService();
    _refreshCaptureState();
  }

  Future<void> _refreshCaptureState() async {
    final granted = await _captureService.hasPermission();
    await _captureService.start();
    if (!mounted) return;
    setState(() {
      _captureRunning = _captureService.isStarted;
      _hasPermission = granted;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from Android notification access settings, refresh state.
    if (state == AppLifecycleState.resumed) {
      _refreshCaptureState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _showSystemNotifications(BuildContext context, AuthProvider auth) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _SystemNotificationsSheet(
          api: auth.api,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 30),
            SizedBox(width: 8),
            Text('Payment Notify'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showSystemNotifications(context, auth),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'System notifications',
          ),
          IconButton(
            onPressed: () async => auth.logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                _captureRunning ? Icons.notifications_active : Icons.notifications_off,
              ),
              title: const Text('Payment capture service'),
              subtitle: Text(
                _captureRunning
                    ? 'Running: listening for PalPay/Jawwal/Bank/SMS notifications'
                    : (_hasPermission
                          ? 'Starting…'
                          : 'Notification access is required to capture payments'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_hasPermission)
                    TextButton(
                      onPressed: _openingSettings
                          ? null
                          : () async {
                              final ok = await _captureService.hasPermission();
                              if (!ok) {
                                setState(() => _openingSettings = true);
                                await _captureService.openPermissionSettings();
                                if (mounted) setState(() => _openingSettings = false);
                                return;
                              }
                              await _refreshCaptureState();
                            },
                      child: const Text('Enable'),
                    ),
                  if (_hasPermission && !_captureRunning)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (_hasPermission && _captureRunning)
                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _refreshCaptureState,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh status',
                  ),
                ],
              ),
            ),
          ),
          _DashboardTile(
            title: 'Subscription',
            subtitle: 'View status and expiry date',
            icon: Icons.credit_card_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
          _DashboardTile(
            title: 'Notification Center',
            subtitle: 'Payment notifications sent to target email',
            icon: Icons.notifications_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              );
            },
          ),
          _DashboardTile(
            title: 'Profile Settings',
            subtitle: 'Target email and account preferences',
            icon: Icons.person_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Offline queue auto-flushes when internet returns and every 30s.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SystemNotificationsSheet extends StatefulWidget {
  const _SystemNotificationsSheet({
    required this.api,
    required this.scrollController,
  });

  final ApiClient api;
  final ScrollController scrollController;

  @override
  State<_SystemNotificationsSheet> createState() => _SystemNotificationsSheetState();
}

class _SystemNotificationsSheetState extends State<_SystemNotificationsSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.api.get('/notifications?limit=50');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final container = body['data'] as Map<String, dynamic>;
        final list = (container['data'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) setState(() => _items = list);
      } else {
        if (mounted) setState(() => _error = 'Failed to load (${res.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Network error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    await widget.api.put('/notifications/$id/read');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('System notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : _items.isEmpty
                      ? const Center(child: Text('No system notifications'))
                      : ListView.builder(
                          controller: widget.scrollController,
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            final id = (n['_id'] ?? '').toString();
                            return ListTile(
                              title: Text((n['title'] ?? '').toString()),
                              subtitle: Text((n['message'] ?? '').toString()),
                              trailing: n['isRead'] == true
                                  ? const Icon(Icons.done, size: 18, color: Colors.green)
                                  : TextButton(
                                      onPressed: () => _markAsRead(id),
                                      child: const Text('Mark read'),
                                    ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

