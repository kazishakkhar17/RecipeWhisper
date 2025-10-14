import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_services.dart';
import '../../../recipes/domain/entities/recipe.dart';

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
  final LMStudioService _aiService;

  AiChatNotifier(this._aiService) : super(AiChatState()) {
    _initializeChat();
  }

  void _initializeChat() {
    final welcomeMessage = ChatMessage(
      text: "👋 Hi! I'm your AI recipe assistant. I can help you create recipes, suggest cooking tips, and answer your culinary questions. What would you like to cook today?",
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
      // Build conversation history
      final conversationHistory = _buildConversationHistory();

      // Get AI response
      final aiResponse = await _aiService.sendMessage(
        message: userMessage,
        conversationHistory: conversationHistory,
      );

      // Check if response contains a recipe
      final recipe = _parseRecipeFromResponse(aiResponse);

      // Add AI message
      final aiChatMessage = ChatMessage(
        text: recipe != null 
            ? "Great! I've created a recipe for you. You can save it to your collection using the button below."
            : aiResponse,
        isUser: false,
      );

      state = state.copyWith(
        messages: [...state.messages, aiChatMessage],
        isLoading: false,
      );

      return recipe;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: ${e.toString()}',
      );
      
      // Add error message to chat
      final errorMessage = ChatMessage(
        text: "Sorry, I encountered an error. Please make sure LM Studio is running on localhost:1234 and try again.",
        isUser: false,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
      );
      
      return null;
    }
  }

  List<Map<String, String>> _buildConversationHistory() {
    final history = <Map<String, String>>[];
    
    // Add system prompt
    history.add({
      'role': 'system',
      'content': _aiService.systemPrompt,
    });

    // Add conversation messages
    for (var message in state.messages) {
      history.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    return history;
  }

  Recipe? _parseRecipeFromResponse(String response) {
    try {
      // Try to find JSON in the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) return null;

      final jsonString = jsonMatch.group(0)!;
      final data = jsonDecode(jsonString);

      // Check if it's a recipe creation action
      if (data['action'] != 'CREATE_RECIPE' || data['recipe'] == null) {
        return null;
      }

      final recipeData = data['recipe'];

      // Create recipe from the data
      return Recipe.create(
        name: recipeData['name'] ?? 'Untitled Recipe',
        description: recipeData['description'] ?? '',
        ingredients: List<String>.from(recipeData['ingredients'] ?? []),
        instructions: List<String>.from(recipeData['instructions'] ?? []),
        cookingTimeMinutes: recipeData['cookingTimeMinutes'] ?? 30,
        servings: recipeData['servings'] ?? 2,
        category: recipeData['category'] ?? 'Other',
      );
    } catch (e) {
      print('Error parsing recipe: $e');
      return null;
    }
  }

  void clearChat() {
    state = AiChatState();
    _initializeChat();
  }
}

// Provider
final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final aiService = LMStudioService();
  return AiChatNotifier(aiService);
});