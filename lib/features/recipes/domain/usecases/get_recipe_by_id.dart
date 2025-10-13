import 'package:bli_flutter_recipewhisper/features/recipes/domain/entities/recipe.dart';
import 'package:bli_flutter_recipewhisper/features/recipes/domain/repositories/recipe_repository.dart';

class GetRecipeById {
  final RecipeRepository repository;

  GetRecipeById(this.repository);

  Future<Recipe?> call(String id) async {
    return await repository.getRecipeById(id);
  }
}