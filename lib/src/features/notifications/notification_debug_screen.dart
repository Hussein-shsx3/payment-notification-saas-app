import 'dart:convert';

import 'package:flutter/material.dart';

import 'services/android_notification_capture_service.dart';

class NotificationDebugScreen extends StatelessWidget {
  const NotificationDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AndroidNotificationCaptureService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Debug'),
        actions: [
          IconButton(
            tooltip: 'Simulate test capture',
            onPressed: () => service.simulateCapture(),
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Clear debug list',
            onPressed: () {
              service.debugEvents.value = const [];
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: service.debugEvents,
        builder: (context, events, _) {
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No capture events yet.\nTrigger notifications on device or use play button.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = events[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e['status'] ?? 'event'} • ${e['source'] ?? 'Unknown source'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e['time'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e['title']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e['message']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        const JsonEncoder.withIndent('  ').convert(e),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

