import 'package:flutter/material.dart';

class AppLocales {
  static const Locale english = Locale('en', 'US');
  static const Locale bangla = Locale('bn', 'BD');

  static const List<Locale> supportedLocales = [
    english,
    bangla,
  ];

  static const List<String> supportedLanguageCodes = ['en', 'bn'];
}