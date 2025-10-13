import 'package:bli_flutter_recipewhisper/features/recipes/domain/entities/recipe.dart';
import 'package:bli_flutter_recipewhisper/features/recipes/domain/repositories/recipe_repository.dart';

class SearchRecipes {
  final RecipeRepository repository;

  SearchRecipes(this.repository);

  Future<List<Recipe>> call(String query) async {
    return await repository.searchRecipes(query);
  }
}