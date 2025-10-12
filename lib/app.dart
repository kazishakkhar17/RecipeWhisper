import 'package:bli_flutter_recipewhisper/core/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bli_flutter_recipewhisper/core/theme/app_theme.dart';
import 'package:bli_flutter_recipewhisper/core/theme/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/delegates.dart';
import 'core/constants/locales.dart';

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
      
      // Add localization support
      supportedLocales: AppLocales.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}