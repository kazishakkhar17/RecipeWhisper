class SearchRecipes {
  final RecipeRepository repository;

  SearchRecipes(this.repository);

  Future<List<Recipe>> call(String query) async {
    return await repository.searchRecipes(query);
  }
}