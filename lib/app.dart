import 'package:bli_flutter_recipewhisper/core/services/localizatiion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bli_flutter_recipewhisper/core/theme/app_theme.dart';
import 'package:bli_flutter_recipewhisper/core/theme/theme_provider.dart';

import 'core/router/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Recipe Whisper',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
