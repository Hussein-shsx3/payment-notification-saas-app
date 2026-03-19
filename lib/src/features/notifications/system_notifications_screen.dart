import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';

class SystemNotificationsScreen extends StatefulWidget {
  const SystemNotificationsScreen({super.key});

  @override
  State<SystemNotificationsScreen> createState() => _SystemNotificationsScreenState();
}

class _SystemNotificationsScreenState extends State<SystemNotificationsScreen> {
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
      final api = context.read<AuthProvider>().api;
      final res = await api.get('/notifications');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final container = body['data'] as Map<String, dynamic>;
        final list = (container['data'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() => _items = list);
      } else {
        setState(() => _error = 'Failed to load system notifications (${res.statusCode}).');
      }
    } catch (_) {
      setState(() => _error = 'Network error while loading system notifications.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    final api = context.read<AuthProvider>().api;
    await api.put('/notifications/$id/read');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                if (_items.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No system notifications yet'),
                      subtitle: Text('System/admin notifications will appear here.'),
                    ),
                  )
                else
                  ..._items.map((n) => Card(
                        child: ListTile(
                          title: Text((n['title'] ?? '').toString()),
                          subtitle: Text((n['message'] ?? '').toString()),
                          trailing: (n['isRead'] == true)
                              ? const Icon(Icons.done, size: 18)
                              : TextButton(
                                  onPressed: () => _markAsRead((n['_id'] ?? '').toString()),
                                  child: const Text('Mark read'),
                                ),
                        ),
                      )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
