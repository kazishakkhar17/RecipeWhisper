import 'package:bli_flutter_recipewhisper/features/recipes/domain/repositories/recipe_repository.dart';

class DeleteRecipe {
  final RecipeRepository repository;

  DeleteRecipe(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteRecipe(id);
  }
}