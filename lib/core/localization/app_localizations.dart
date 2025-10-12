import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale) {
    _localizedStrings = AppStrings.getStrings(locale.languageCode);
  }

  // Helper method to get localized string
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Static method to access AppLocalizations from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static method to check if locale is supported
  static bool isSupported(Locale locale) {
    return ['en', 'bn'].contains(locale.languageCode);
  }
}

// Extension for easier access
extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
  
  String tr(String key) => AppLocalizations.of(this).translate(key);
}