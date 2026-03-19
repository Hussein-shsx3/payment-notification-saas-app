import 'package:flutter/material.dart';

import 'services/capture_settings_service.dart';

class NotificationCaptureSettingsScreen extends StatefulWidget {
  const NotificationCaptureSettingsScreen({super.key});

  @override
  State<NotificationCaptureSettingsScreen> createState() =>
      _NotificationCaptureSettingsScreenState();
}

class _NotificationCaptureSettingsScreenState
    extends State<NotificationCaptureSettingsScreen> {
  final _settings = CaptureSettingsService();
  Map<String, bool>? _values;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await _settings.getAll();
    if (!mounted) return;
    setState(() {
      _values = map;
    });
  }

  @override
  Widget build(BuildContext context) {
    final values = _values;
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Settings')),
      body: values == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Enable only sources you want to forward to backend.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                for (final source in CaptureSettingsService.allSources)
                  Card(
                    child: SwitchListTile(
                      title: Text(source),
                      value: values[source] ?? true,
                      onChanged: (enabled) async {
                        setState(() {
                          values[source] = enabled;
                        });
                        await _settings.setEnabled(source, enabled);
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

