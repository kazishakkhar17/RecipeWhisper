import 'package:hive/hive.dart';
import '../../domain/entities/recipe.dart';

class HiveRecipeDataSource {
  static const String _boxName = 'recipesBox';

  Box<Recipe> get _box => Hive.box<Recipe>(_boxName);

  // Get all recipes
  Future<List<Recipe>> getAllRecipes() async {
    return _box.values.toList();
  }

  // Get recipe by ID
  Future<Recipe?> getRecipeById(String id) async {
    return _box.values.firstWhere(
      (recipe) => recipe.id == id,
      orElse: () => throw Exception('Recipe not found'),
    );
  }

  // Add recipe
  Future<void> addRecipe(Recipe recipe) async {
    await _box.put(recipe.id, recipe);
  }

  // Update recipe
  Future<void> updateRecipe(Recipe recipe) async {
    await _box.put(recipe.id, recipe);
  }

  // Delete recipe
  Future<void> deleteRecipe(String id) async {
    await _box.delete(id);
  }

  // Search recipes by name
  Future<List<Recipe>> searchRecipes(String query) async {
    if (query.isEmpty) return getAllRecipes();
    
    final lowerQuery = query.toLowerCase();
    return _box.values.where((recipe) {
      return recipe.name.toLowerCase().contains(lowerQuery) ||
             recipe.description.toLowerCase().contains(lowerQuery) ||
             recipe.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    return _box.values.where((recipe) => recipe.category == category).toList();
  }

  // Clear all recipes (for testing)
  Future<void> clearAllRecipes() async {
    await _box.clear();
  }

  // Get total count
  int getRecipeCount() {
    return _box.length;
  }
}