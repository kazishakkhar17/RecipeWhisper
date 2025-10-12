import 'package:bli_flutter_recipewhisper/core/services/localizatiion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return ElevatedButton(
      onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
      child: Text(locale.languageCode == 'en' ? 'EN' : 'BN'),
    );
  }
}
