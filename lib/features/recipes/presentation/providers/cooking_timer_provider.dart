import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../reminders/presentation/utils/notification_helper.dart';
import '../../domain/entities/recipe.dart';

class CookingTimerState {
  final int remainingSeconds;
  final bool isRunning;

  CookingTimerState({required this.remainingSeconds, this.isRunning = false});

  CookingTimerState copyWith({int? remainingSeconds, bool? isRunning}) {
    return CookingTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class CookingTimerNotifier extends StateNotifier<CookingTimerState> {
  Timer? _timer;
  Recipe? currentRecipe;
  late Box _box;

  CookingTimerNotifier() : super(CookingTimerState(remainingSeconds: 0)) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox('cooking_timer_box');
    final storedRecipeId = _box.get('recipeId');
    final remaining = _box.get('remainingSeconds') ?? 0;
    final running = _box.get('isRunning') ?? false;

    if (storedRecipeId != null) {
      currentRecipe = Recipe(
        id: storedRecipeId,
        name: '',
        description: '',
        cookingTimeMinutes: 0,
        calories: 0,
        category: '',
        ingredients: [],
        instructions: [],
        createdAt: DateTime.now(),
      );

      state = CookingTimerState(remainingSeconds: remaining, isRunning: running);
      if (running) _startTimer();
    }
  }

  void startTimer(Recipe recipe) {
    currentRecipe = recipe;
    _timer?.cancel();
    state = CookingTimerState(remainingSeconds: recipe.cookingTimeMinutes * 60, isRunning: true);
    _saveToHive();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        _saveToHive();
      } else {
        // Timer finished
        if (currentRecipe != null) {
          // 🔔 Fire notification immediately
          NotificationHelper.showNotification(
            title: 'Cooking Complete!',
            body: '${currentRecipe!.name} is ready to serve 🍽️',
          );
        }
        stopTimer(); // stop the timer and clear state
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _saveToHive();
  }

  void resumeTimer() {
    if (currentRecipe != null) {
      state = state.copyWith(isRunning: true);
      _saveToHive();
      _startTimer();
    }
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
    currentRecipe = null;
    _box.clear();
  }

  void _saveToHive() {
    if (currentRecipe != null) {
      _box.put('recipeId', currentRecipe!.id);
      _box.put('remainingSeconds', state.remainingSeconds);
      _box.put('isRunning', state.isRunning);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final cookingTimerProvider = StateNotifierProvider<CookingTimerNotifier, CookingTimerState>(
  (ref) => CookingTimerNotifier(),
);