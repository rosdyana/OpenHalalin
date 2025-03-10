import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';
  final SharedPreferences _prefs;

  Locale _currentLocale;

  LanguageProvider(this._prefs)
      : _currentLocale = Locale(_prefs.getString(_languageKey) ?? 'en');

  Locale get currentLocale => _currentLocale;

  static final Map<String, String> supportedLanguages = {
    'en': 'English',
    'id': 'Indonesia',
    'zh': '繁體中文',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
    'de': 'Deutsch',
    'nl': 'Nederlands',
    'it': 'Italiano',
    'es': 'Español',
    'pt': 'Português',
    'vi': 'Tiếng Việt',
  };

  static final Map<String, String> nativeLanguageNames = {
    'en': 'English',
    'id': 'Bahasa Indonesia',
    'zh': '繁體中文',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
    'de': 'Deutsch',
    'nl': 'Nederlands',
    'it': 'Italiano',
    'es': 'Español',
    'pt': 'Português',
    'vi': 'Tiếng Việt',
  };

  String getCurrentLanguageName() {
    return nativeLanguageNames[_currentLocale.languageCode] ?? 'English';
  }

  Future<void> setLocale(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) return;

    await _prefs.setString(_languageKey, languageCode);
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  bool isRTL() {
    // Add RTL languages here if needed in the future
    final rtlLanguages = <String>[];
    return rtlLanguages.contains(_currentLocale.languageCode);
  }
}
