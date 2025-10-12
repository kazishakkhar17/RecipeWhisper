import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../constants/locales.dart';

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences prefs;
  static const _localeKey = 'locale_code';

  LocaleNotifier(this.prefs) : super(_loadLocale(prefs));

  static Locale _loadLocale(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey) ?? 'en';
    return Locale(code);
  }

  void toggleLocale() {
    if (state.languageCode == 'en') {
      setLocale(AppLocales.bangla);
    } else {
      setLocale(AppLocales.english);
    }
  }

  void setLocale(Locale locale) {
    state = locale;
    prefs.setString(_localeKey, locale.languageCode);
  }

  String get currentLanguageName {
    return state.languageCode == 'en' ? 'English' : 'বাংলা';
  }

  bool get isEnglish => state.languageCode == 'en';
  bool get isBangla => state.languageCode == 'bn';
}