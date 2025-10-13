import 'package:hive/hive.dart';

class RecipeDatasource {
  static const _boxName = 'timerBox';

  Future<void> saveCurrentTimer({
    required String recipeId,
    required int remainingSeconds,
    required bool isRunning,
  }) async {
    final box = await Hive.openBox(_boxName);
    await box.put('currentRecipeId', recipeId);
    await box.put('remainingSeconds', remainingSeconds);
    await box.put('isRunning', isRunning);
  }

  Future<Map<String, dynamic>?> loadCurrentTimer() async {
    final box = await Hive.openBox(_boxName);
    final recipeId = box.get('currentRecipeId');
    final remainingSeconds = box.get('remainingSeconds');
    final isRunning = box.get('isRunning');

    if (recipeId != null && remainingSeconds != null && isRunning != null) {
      return {
        'recipeId': recipeId as String,
        'remainingSeconds': remainingSeconds as int,
        'isRunning': isRunning as bool,
      };
    }
    return null;
  }

  Future<void> clearCurrentTimer() async {
    final box = await Hive.openBox(_boxName);
    await box.delete('currentRecipeId');
    await box.delete('remainingSeconds');
    await box.delete('isRunning');
  }
}
