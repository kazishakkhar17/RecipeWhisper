class UpdateRecipe {
  final RecipeRepository repository;

  UpdateRecipe(this.repository);

  Future<void> call(Recipe recipe) async {
    return await repository.updateRecipe(recipe);
  }
}