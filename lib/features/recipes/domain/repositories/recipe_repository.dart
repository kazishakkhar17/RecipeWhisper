import '../entities/recipe.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> getAllRecipes();
  Future<Recipe?> getRecipeById(String id);
  Future<void> addRecipe(Recipe recipe);
  Future<void> updateRecipe(Recipe recipe);
  Future<void> deleteRecipe(String id);
  Future<List<Recipe>> searchRecipes(String query);
  Future<List<Recipe>> getRecipesByCategory(String category);
  int getRecipeCount();
}