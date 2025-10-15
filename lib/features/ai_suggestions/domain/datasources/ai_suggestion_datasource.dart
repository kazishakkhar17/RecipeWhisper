import '../../../recipes/domain/entities/recipe.dart';

abstract class AiSuggestionDatasource {
  /// Generate a recipe suggestion based on user input
  Future<Recipe> generateRecipeSuggestion(String userInput);
  
  /// Generate multiple recipe suggestions
  Future<List<Recipe>> generateMultipleSuggestions(String userInput, {int count = 3});
  
  /// Get a conversational response from AI
  Future<String> getChatResponse(String message);
}