import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists UI language (English / Arabic). RTL is applied automatically for Arabic.
class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_prefsKey);
    if (code == 'ar') {
      _locale = const Locale('ar');
      notifyListeners();
    } else if (code == 'en') {
      _locale = const Locale('en');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (code != 'ar' && code != 'en') return;
    _locale = Locale(code);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, code);
  }
}
