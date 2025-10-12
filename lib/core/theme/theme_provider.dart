import 'package:bli_flutter_recipewhisper/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';


final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences prefs;
  static const _themeKey = 'theme_mode';

  ThemeNotifier(this.prefs) : super(_loadTheme(prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    return ThemeMode.values[themeIndex];
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
    prefs.setInt(_themeKey, state.index);
  }
}
