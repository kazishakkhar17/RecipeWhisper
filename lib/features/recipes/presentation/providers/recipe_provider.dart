import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/datasources/hive_recipe_datasource.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';

// Data source provider
final recipeDataSourceProvider = Provider<HiveRecipeDataSource>((ref) {
  return HiveRecipeDataSource();
});

// Repository provider
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final dataSource = ref.watch(recipeDataSourceProvider);
  return RecipeRepositoryImpl(dataSource);
});

// Recipe list provider
final recipeListProvider = StateNotifierProvider<RecipeNotifier, AsyncValue<List<Recipe>>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return RecipeNotifier(repository);
});

// Recipe search provider
final recipeSearchProvider = StateProvider<String>((ref) => '');

// Filtered recipes provider
final filteredRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final recipesAsync = ref.watch(recipeListProvider);
  final searchQuery = ref.watch(recipeSearchProvider);

  return recipesAsync.when(
    data: (recipes) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(recipes);
      }
      final filtered = recipes.where((recipe) {
        final lowerQuery = searchQuery.toLowerCase();
        return recipe.name.toLowerCase().contains(lowerQuery) ||
               recipe.description.toLowerCase().contains(lowerQuery) ||
               recipe.category.toLowerCase().contains(lowerQuery);
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class RecipeNotifier extends StateNotifier<AsyncValue<List<Recipe>>> {
  final RecipeRepository _repository;

  RecipeNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initializeDefaultRecipes().then((_) => loadRecipes());
  }

  /// --- NEW: Initialize default recipes from JSON ---
  Future<void> _initializeDefaultRecipes() async {
    final box = await Hive.openBox('app_settings');
    final isFirstRun = box.get('is_first_run', defaultValue: true) as bool;

    if (!isFirstRun) return;

    try {
      final jsonString = await rootBundle.loadString('assets/default_recipes.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      for (final jsonItem in jsonList) {
        final exists = await _repository.getRecipeById(jsonItem['id']);
        if (exists != null) continue; // prevent duplicates

        final recipe = Recipe(
  id: jsonItem['id'],
  name: jsonItem['name'],
  description: jsonItem['description'],
  ingredients: List<String>.from(jsonItem['ingredients']),
  instructions: List<String>.from(jsonItem['instructions']),
  category: jsonItem['category'] ?? 'Other',
  cookingTimeMinutes: jsonItem['cookingTimeMinutes'],
  calories: jsonItem['calories'],
  createdAt: DateTime.now(),       // <-- Required field
  updatedAt: DateTime.now(),       // <-- Optional, can use null if you want
);

        await _repository.addRecipe(recipe);
      }

      await box.put('is_first_run', false);
    } catch (e) {
      // If JSON load fails, silently continue
      print('Failed to load default recipes: $e');
    }
  }

  // Load all recipes
  Future<void> loadRecipes() async {
    state = const AsyncValue.loading();
    try {
      final recipes = await _repository.getAllRecipes();
      state = AsyncValue.data(recipes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Add recipe
  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _repository.addRecipe(recipe);
      await loadRecipes(); // Reload list
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Update recipe
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _repository.updateRecipe(recipe);
      await loadRecipes(); // Reload list
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Delete recipe
  Future<void> deleteRecipe(String id) async {
    try {
      await _repository.deleteRecipe(id);
      await loadRecipes(); // Reload list
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Get recipe by ID
  Future<Recipe?> getRecipeById(String id) async {
    try {
      return await _repository.getRecipeById(id);
    } catch (e) {
      return null;
    }
  }
}
