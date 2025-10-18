import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../reminders/presentation/utils/notification_helper.dart';
import '../../domain/entities/recipe.dart';
import '../providers/recipe_provider.dart';

class CookingTimerState {
  final int remainingSeconds;
  final bool isRunning;
  final Recipe? recipe; // ADDED: Store recipe in state

  CookingTimerState({
    required this.remainingSeconds, 
    this.isRunning = false,
    this.recipe, // ADDED
  });

  CookingTimerState copyWith({
    int? remainingSeconds, 
    bool? isRunning,
    Recipe? recipe, // ADDED
  }) {
    return CookingTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      recipe: recipe ?? this.recipe, // ADDED
    );
  }
}

class CookingTimerNotifier extends StateNotifier<CookingTimerState> {
  Timer? _timer;
  Recipe? currentRecipe;
  late Box _box;
  final Ref ref; // ADDED: Keep ref to access recipe provider

  // CHANGED: Accept Ref in constructor
  CookingTimerNotifier(this.ref) : super(CookingTimerState(remainingSeconds: 0)) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox('cooking_timer_box');
    
    // CHANGED: Load recipe ID and fetch full recipe from repository
    final storedRecipeId = _box.get('recipeId');
    final remaining = _box.get('remainingSeconds') ?? 0;
    final running = _box.get('isRunning') ?? false;

    if (storedRecipeId != null) {
      try {
        // ADDED: Fetch recipe from recipe repository
        final recipeNotifier = ref.read(recipeListProvider.notifier);
        final recipe = await recipeNotifier.getRecipeById(storedRecipeId);
        
        if (recipe != null) {
          currentRecipe = recipe;
          
          state = CookingTimerState(
            remainingSeconds: remaining, 
            isRunning: running,
            recipe: recipe, // ADDED: Store in state
          );
          
          if (running && remaining > 0) {
            _startTimer();
          }
        } else {
          // Recipe not found, clear timer data
          _box.clear();
        }
      } catch (e) {
        print('Error loading recipe: $e');
        _box.clear();
      }
    }
  }

  void startTimer(Recipe recipe) {
    currentRecipe = recipe;
    _timer?.cancel();
    state = CookingTimerState(
      remainingSeconds: recipe.cookingTimeMinutes * 60, 
      isRunning: true,
      recipe: recipe, // ADDED: Store in state
    );
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
    state = CookingTimerState(remainingSeconds: 0, isRunning: false, recipe: null);
    currentRecipe = null;
    _box.clear();
  }

  void _saveToHive() {
    if (currentRecipe != null) {
      // CHANGED: Save only recipe ID, full recipe is in recipe repository
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

// CHANGED: Pass ref to notifier
final cookingTimerProvider = StateNotifierProvider<CookingTimerNotifier, CookingTimerState>(
  (ref) => CookingTimerNotifier(ref),
);