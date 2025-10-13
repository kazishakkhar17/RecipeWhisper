import 'package:bli_flutter_recipewhisper/features/recipes/domain/entities/recipe.dart';
import 'package:bli_flutter_recipewhisper/features/recipes/domain/repositories/recipe_repository.dart';

class UpdateRecipe {
  final RecipeRepository repository;

  UpdateRecipe(this.repository);

  Future<void> call(Recipe recipe) async {
    return await repository.updateRecipe(recipe);
  }
}