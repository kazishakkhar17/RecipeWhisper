import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/hive_recipe_datasource.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final HiveRecipeDataSource _dataSource;

  RecipeRepositoryImpl(this._dataSource);

  @override
  Future<List<Recipe>> getAllRecipes() async {
    try {
      return await _dataSource.getAllRecipes();
    } catch (e) {
      throw Exception('Failed to get recipes: $e');
    }
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    try {
      return await _dataSource.getRecipeById(id);
    } catch (e) {
      throw Exception('Failed to get recipe: $e');
    }
  }

  @override
  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _dataSource.addRecipe(recipe);
    } catch (e) {
      throw Exception('Failed to add recipe: $e');
    }
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      final updatedRecipe = recipe.copyWith(updatedAt: DateTime.now());
      await _dataSource.updateRecipe(updatedRecipe);
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  @override
  Future<void> deleteRecipe(String id) async {
    try {
      await _dataSource.deleteRecipe(id);
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  @override
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      return await _dataSource.searchRecipes(query);
    } catch (e) {
      throw Exception('Failed to search recipes: $e');
    }
  }

  @override
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      return await _dataSource.getRecipesByCategory(category);
    } catch (e) {
      throw Exception('Failed to get recipes by category: $e');
    }
  }

  @override
  int getRecipeCount() {
    return _dataSource.getRecipeCount();
  }
}