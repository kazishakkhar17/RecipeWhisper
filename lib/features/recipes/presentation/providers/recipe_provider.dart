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
    _initialize();
  }

  /// Initialize and load recipes
  Future<void> _initialize() async {
    await _ensureDefaultRecipes();
    await loadRecipes();
  }

  /// ✅ BEST APPROACH: Check flag + empty database
  /// Only loads defaults if:
  /// 1. Defaults were never loaded before (flag is false)
  /// 2. AND database is empty
  Future<void> _ensureDefaultRecipes() async {
    try {
      final box = await Hive.openBox('app_settings');
      final defaultsLoaded = box.get('defaults_loaded', defaultValue: false) as bool;

      // If defaults were already loaded once, never reload automatically
      if (defaultsLoaded) {
        print('✅ Defaults were loaded before, skipping');
        return;
      }

      // Check if database is empty
      final existingRecipes = await _repository.getAllRecipes();
      if (existingRecipes.isNotEmpty) {
        print('✅ Database has recipes, marking defaults as loaded');
        await box.put('defaults_loaded', true);
        return;
      }

      print('📦 First time setup - loading default recipes...');

      // Load JSON file
      final jsonString = await rootBundle.loadString('assets/default_recipes.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      print('📝 Found ${jsonList.length} default recipes');

      // Add each recipe
      int addedCount = 0;
      for (final jsonItem in jsonList) {
        try {
          // Create recipe entity
          final recipe = Recipe(
            id: jsonItem['id'],
            name: jsonItem['name'],
            description: jsonItem['description'],
            ingredients: List<String>.from(jsonItem['ingredients']),
            instructions: List<String>.from(jsonItem['instructions']),
            category: jsonItem['category'] ?? 'Other',
            cookingTimeMinutes: jsonItem['cookingTimeMinutes'] ?? 30,
            calories: jsonItem['calories'] ?? 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Add to repository (no duplicate check needed on first run)
          await _repository.addRecipe(recipe);
          addedCount++;
          print('✅ Added: ${recipe.name}');
        } catch (e) {
          print('❌ Error adding recipe ${jsonItem['id']}: $e');
        }
      }

      // Mark defaults as loaded (so they never auto-reload)
      await box.put('defaults_loaded', true);
      print('🎉 Successfully added $addedCount default recipes');
    } catch (e, stack) {
      print('❌ Failed to load default recipes: $e');
      print('Stack trace: $stack');
    }
  }

  // Load all recipes
  Future<void> loadRecipes() async {
    state = const AsyncValue.loading();
    try {
      final recipes = await _repository.getAllRecipes();
      print('📚 Loaded ${recipes.length} recipes');
      state = AsyncValue.data(recipes);
    } catch (e, stack) {
      print('❌ Error loading recipes: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Add recipe
  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _repository.addRecipe(recipe);
      await loadRecipes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Update recipe
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _repository.updateRecipe(recipe);
      await loadRecipes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Delete recipe
  Future<void> deleteRecipe(String id) async {
    try {
      await _repository.deleteRecipe(id);
      await loadRecipes();
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

  /// Manual reset - User explicitly wants to restore defaults
  /// Call this from a "Restore Default Recipes" button in settings
  Future<void> restoreDefaults() async {
    try {
      print('🔄 User requested restore defaults...');
      
      // Clear all recipes
      final allRecipes = await _repository.getAllRecipes();
      for (final recipe in allRecipes) {
        await _repository.deleteRecipe(recipe.id);
      }
      
      print('🗑️ Cleared all recipes');
      
      // Reset the flag
      final box = await Hive.openBox('app_settings');
      await box.put('defaults_loaded', false);
      
      // Reload defaults
      await _ensureDefaultRecipes();
      await loadRecipes();
      
      print('✅ Defaults restored');
    } catch (e) {
      print('❌ Error restoring defaults: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}