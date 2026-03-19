import 'package:hive/hive.dart';

class CaptureSettingsService {
  static const String _boxName = 'capture_settings';

  static const String sourcePalPay = 'PalPay';
  static const String sourceJawwal = 'Jawwal Pay';
  static const String sourceBank = 'Palestine Bank';
  static const String sourceIburaq = 'Iburaq';
  static const String sourceSms = 'SMS Payment';

  static const List<String> allSources = [
    sourcePalPay,
    sourceJawwal,
    sourceBank,
    sourceIburaq,
    sourceSms,
  ];

  Future<Box<dynamic>> _box() async => Hive.openBox<dynamic>(_boxName);

  Future<bool> isEnabled(String source) async {
    final box = await _box();
    final key = _sourceKey(source);
    final value = box.get(key);
    if (value is bool) return value;
    return true;
  }

  Future<void> setEnabled(String source, bool enabled) async {
    final box = await _box();
    await box.put(_sourceKey(source), enabled);
  }

  Future<Map<String, bool>> getAll() async {
    final box = await _box();
    final map = <String, bool>{};
    for (final source in allSources) {
      final value = box.get(_sourceKey(source));
      map[source] = value is bool ? value : true;
    }
    return map;
  }

  String _sourceKey(String source) => 'enabled_${source.toLowerCase().replaceAll(' ', '_')}';
}

