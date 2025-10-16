import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';
import 'package:bli_flutter_recipewhisper/core/theme/theme_provider.dart';

import '../../../../core/services/localization_service.dart';

class SettingsWidget extends ConsumerWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final isEnglish = ref.watch(localeProvider).languageCode == 'en';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('settings'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Dark Theme Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: const Color(0xFFFF6B6B)),
                    ),
                    const SizedBox(width: 12),
                    Text(context.tr('dark_theme'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                Switch(
                  value: isDarkMode,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                  activeColor: const Color(0xFFFF6B6B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Language Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language, color: Color(0xFFFF6B6B)),
                    ),
                    const SizedBox(width: 12),
                    Text(context.tr('language'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                Switch(
                  value: isEnglish,
                  onChanged: (_) => ref.read(localeProvider.notifier).toggleLocale(),
                  activeColor: const Color(0xFFFF6B6B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
