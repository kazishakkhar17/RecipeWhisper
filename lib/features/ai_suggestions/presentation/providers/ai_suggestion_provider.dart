import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_services.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../../../recipes/presentation/providers/recipe_provider.dart';

// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Chat state
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// AI Chat Provider
class AiChatNotifier extends StateNotifier<AiChatState> {
  final GroqService _aiService;
  final Ref _ref;

  AiChatNotifier(this._aiService, this._ref) : super(AiChatState()) {
    _initializeChat();
  }

  void _initializeChat() {
    final welcomeMessage = ChatMessage(
      text:
          "👋 Hi! I'm your AI recipe assistant powered by Groq. Just tell me what dish you want (e.g., 'spaghetti bolognese', 'chocolate chip cookies'), and I'll instantly create a complete recipe for you!\n\nYou can also ask me for cooking tips, meal suggestions, or help with meal planning. 🍳",
      isUser: false,
    );
    state = state.copyWith(messages: [welcomeMessage]);
  }

  Future<Recipe?> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return null;

    // Add user message
    final userChatMessage = ChatMessage(text: userMessage, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userChatMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Get AI response from Groq
      final aiResponse = await _aiService.sendMessage(
        message: userMessage,
      );

      print('🤖 Raw AI Response:\n$aiResponse\n---END RESPONSE---');

      // Try to parse recipe from response
      final recipe = _parseRecipeFromResponse(aiResponse);

      if (recipe != null) {
        print('✅ Recipe parsed successfully: ${recipe.name}');

        // Add the recipe to Hive through RecipeNotifier
        await _ref.read(recipeListProvider.notifier).addRecipe(recipe);
        print('💾 Recipe added to Hive');

        // Add success message
        final successMessage = ChatMessage(
          text:
              "✅ Perfect! I've created and saved '${recipe.name}' to your recipe collection.\n\n📋 Summary:\n• Cook time: ${recipe.cookingTimeMinutes} minutes\n• Calories: ${recipe.calories}\n• Category: ${recipe.category}\n• Ingredients: ${recipe.ingredients.length}\n• Steps: ${recipe.instructions.length}\n\nYou can find it in your Recipes tab now! 🎉\n\nWant to create another recipe? Just tell me what you'd like to make!",
          isUser: false,
        );

        state = state.copyWith(
          messages: [...state.messages, successMessage],
          isLoading: false,
        );

        return recipe;
      } else {
        // Add fallback message
        final fallbackMessage = ChatMessage(
          text: aiResponse.trim().isNotEmpty
              ? aiResponse
              : "🤖 Hmm, I didn't understand that. Could you try asking in a different way?",
          isUser: false,
        );

        state = state.copyWith(
          messages: [...state.messages, fallbackMessage],
          isLoading: false,
        );

        return null;
      }
    } catch (e) {
      print('❌ Error: $e');

      final errorMessage = ChatMessage(
        text:
            "😕 Sorry, I encountered an error while connecting to Groq API.\n\nPlease make sure:\n1. Your GROQ_API_KEY is set correctly in the .env file\n2. You have an active internet connection\n3. Your API key is valid\n\nError details: ${e.toString()}",
        isUser: false,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        error: 'Error: ${e.toString()}',
      );

      return null;
    }
  }

  Recipe? _parseRecipeFromResponse(String response) {
    try {
      String cleanResponse = response
          .trim()
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .replaceAll(RegExp(r'^\s+', multiLine: true), '')
          .trim();

      final startIndex = cleanResponse.indexOf('{');
      final lastIndex = cleanResponse.lastIndexOf('}');

      if (startIndex == -1 || lastIndex == -1 || startIndex >= lastIndex) {
        return null;
      }

      String jsonString = cleanResponse.substring(startIndex, lastIndex + 1);
      jsonString = jsonString
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(', }', '}')
          .replaceAll(', ]', ']');

      dynamic data = jsonDecode(jsonString);

      if (data is! Map<String, dynamic> || data['action'] != 'CREATE_RECIPE') {
        return null;
      }

      final recipeData = data['recipe'] as Map<String, dynamic>;
      final name = recipeData['name']?.toString().trim() ?? 'Untitled Recipe';
      final description =
          recipeData['description']?.toString().trim() ?? 'A delicious recipe';

      int cookingTime = int.tryParse(
              recipeData['cookingTimeMinutes'].toString().split('.').first) ??
          30;
      int calories = int.tryParse(
              recipeData['calories'].toString().split('.').first) ??
          400;

      final category = recipeData['category']?.toString().trim() ?? 'Other';

      final ingredients = (recipeData['ingredients'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final instructions = (recipeData['instructions'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (name.isEmpty || ingredients.isEmpty || instructions.isEmpty) {
        return null;
      }

      return Recipe.create(
        name: name,
        description: description,
        ingredients: ingredients,
        instructions: instructions,
        cookingTimeMinutes: cookingTime,
        calories: calories,
        category: category,
      );
    } catch (e) {
      print('❌ Failed to parse recipe: $e');
      return null;
    }
  }

  void clearChat() {
    state = AiChatState();
    _initializeChat();
  }
}

// Provider using GroqService
final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final groqService = GroqService();
  return AiChatNotifier(groqService, ref);
});
