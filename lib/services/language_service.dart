import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController {
  LanguageController._private();
  static final LanguageController instance = LanguageController._private();

  static const String _prefKey = 'languageCode';

  final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('en'),
  );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey) ?? 'en';
    localeNotifier.value = Locale(savedCode);
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
    localeNotifier.value = Locale(languageCode);
  }

  String get currentLanguageCode => localeNotifier.value.languageCode;
}

class LanguageModel {
  final String name;
  final String nativeName;
  final String code;
  final String flag;

  LanguageModel({
    required this.name,
    required this.nativeName,
    required this.code,
    required this.flag,
  });
}

final List<LanguageModel> supportedLanguages = [
  LanguageModel(name: 'English', nativeName: 'English', code: 'en', flag: '🇺🇸'),
  LanguageModel(name: 'Japanese', nativeName: '日本語', code: 'ja', flag: '🇯🇵'),
  LanguageModel(name: 'Portuguese', nativeName: 'Português', code: 'pt', flag: '🇵🇹'),
];
