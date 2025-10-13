class GetRecipeById {
  final RecipeRepository repository;

  GetRecipeById(this.repository);

  Future<Recipe?> call(String id) async {
    return await repository.getRecipeById(id);
  }
}