import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/src/features/notifications/services/payment_notification_parser.dart';

void main() {
  test('rejects fake SMS from an untrusted personal-name sender', () {
    final parsed = PaymentNotificationParser.parse(
      packageName: 'com.google.android.apps.messaging',
      title: 'وصلك 13. من اسلام عيسي',
      message: 'شكرا ابو عمر\nJAWWAL\n059-916-1404',
      receivedAt: DateTime.utc(2026, 4, 7),
    );

    expect(parsed, isNull);
  });

  test('accepts a trusted bank sender', () {
    final parsed = PaymentNotificationParser.parse(
      packageName: 'com.google.android.apps.messaging',
      title: 'من BOP',
      message: 'تم ايداع 13 شيكل في حسابك',
      receivedAt: DateTime.utc(2026, 4, 7),
    );

    expect(parsed, isNotNull);
    expect(parsed?.amount, 13);
    expect(parsed?.sender?.toLowerCase(), contains('bop'));
  });
}
