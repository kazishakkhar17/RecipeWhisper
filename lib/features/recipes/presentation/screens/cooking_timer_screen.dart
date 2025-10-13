import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recipe.dart';
import '../providers/cooking_timer_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/app_localizations.dart'; // for context.tr

class CookingTimerScreen extends ConsumerWidget {
  const CookingTimerScreen({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Map<String, Color> getCookingStage(int remainingSeconds, int totalSeconds, BuildContext context) {
    if (remainingSeconds <= 0) return {context.tr('done'): Colors.green};
    final interval = 10;
    final stageNumber = ((totalSeconds - remainingSeconds) / interval).floor();

    final messages = [
      context.tr('stage_just_started'),
      context.tr('stage_heating_up'),
      context.tr('stage_cooking_nicely'),
      context.tr('stage_getting_close'),
      context.tr('stage_almost_done'),
      context.tr('stage_ready_soon'),
    ];

    final colors = [
      Colors.redAccent,
      Colors.deepOrange,
      Colors.orange,
      Colors.yellow[700]!,
      Colors.lightGreen,
      Colors.greenAccent,
    ];

    final index = stageNumber.clamp(0, messages.length - 1);
    return {messages[index]: colors[index]};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(cookingTimerProvider);
    final timerNotifier = ref.read(cookingTimerProvider.notifier);

    if (timerNotifier.currentRecipe == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('no_recipe'))),
        body: Center(child: Text(context.tr('no_active_timer'))),
      );
    }

    final recipe = timerNotifier.currentRecipe!;
    final totalSeconds = recipe.cookingTimeMinutes > 0 ? recipe.cookingTimeMinutes * 60 : 1;
    final progress = ((1 - (timerState.remainingSeconds / totalSeconds))).clamp(0.0, 1.0);

    final stageMap = getCookingStage(timerState.remainingSeconds, totalSeconds, context);
    final stageText = stageMap.keys.first;
    final stageColor = stageMap.values.first;

    return Scaffold(
      appBar: AppBar(title: Text('${context.tr('cooking')} ${recipe.name}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular animated progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(stageColor),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Text(
                    _formatTime(timerState.remainingSeconds),
                    key: ValueKey(timerState.remainingSeconds),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: stageColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                child: Text(
                  stageText,
                  key: ValueKey(stageText),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 50),
            if (timerState.remainingSeconds == 0)
              ElevatedButton(
                onPressed: () {
                  timerNotifier.stopTimer();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                ),
                child: Text(context.tr('finish'), style: const TextStyle(fontSize: 18, color: Colors.white)),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (timerState.isRunning) {
                        timerNotifier.pauseTimer();
                      } else {
                        timerNotifier.resumeTimer();
                      }
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timerState.isRunning ? context.tr('pause') : context.tr('resume'),
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      timerNotifier.stopTimer();
                      Navigator.pop(context);
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(context.tr('finish'), style: const TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
