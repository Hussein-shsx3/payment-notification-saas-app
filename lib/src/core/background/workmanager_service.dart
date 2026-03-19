import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/notifications/services/payment_notification_forwarder.dart';

const String flushQueueTaskName = 'flush_payment_queue_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == flushQueueTaskName) {
      WidgetsFlutterBinding.ensureInitialized();
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
      final forwarder = PaymentNotificationForwarder();
      await forwarder.flushQueue();
    }
    return Future.value(true);
  });
}

class WorkmanagerService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerQueueFlushTask() async {
    await Workmanager().registerPeriodicTask(
      'payment_queue_flush_unique',
      flushQueueTaskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}

