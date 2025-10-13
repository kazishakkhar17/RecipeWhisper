import 'package:bli_flutter_recipewhisper/features/recipes/domain/entities/recipe.dart';
import 'package:bli_flutter_recipewhisper/features/recipes/domain/repositories/recipe_repository.dart';

class GetAllRecipes {
  final RecipeRepository repository;

  GetAllRecipes(this.repository);

  Future<List<Recipe>> call() async {
    return await repository.getAllRecipes();
  }
}
