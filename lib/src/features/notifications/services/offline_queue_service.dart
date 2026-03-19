import 'package:hive/hive.dart';

class OfflineQueueService {
  static const String queueBoxName = 'payment_notification_queue';

  Future<Box<dynamic>> _openBox() async {
    return Hive.openBox<dynamic>(queueBoxName);
  }

  Future<void> enqueue(Map<String, dynamic> payload) async {
    final box = await _openBox();
    await box.add(payload);
  }

  Future<List<Map<String, dynamic>>> all() async {
    final box = await _openBox();
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }
}

