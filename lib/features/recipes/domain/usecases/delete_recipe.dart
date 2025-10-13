class DeleteRecipe {
  final RecipeRepository repository;

  DeleteRecipe(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteRecipe(id);
  }
}