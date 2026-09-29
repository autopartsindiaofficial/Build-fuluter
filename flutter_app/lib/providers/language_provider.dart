import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/translations_data.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    notifyListeners();
  }

  String t(String key) {
    return TranslationsData.get(key, _currentLanguage);
  }
}
