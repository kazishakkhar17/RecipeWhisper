import 'package:bli_flutter_recipewhisper/core/services/localizatiion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bli_flutter_recipewhisper/core/theme/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final isEnglish = ref.watch(localeProvider) == const Locale('en');

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Dark Theme Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Theme'),
                Switch(
                  value: isDarkMode,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),

            // Language Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('English Language'),
                Switch(
                  value: isEnglish,
                  onChanged: (_) => ref.read(localeProvider.notifier).toggleLocale(),
                ),
              ],
            ),
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
