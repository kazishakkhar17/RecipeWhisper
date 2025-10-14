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
  final LMStudioService _aiService;
  final Ref _ref;

  AiChatNotifier(this._aiService, this._ref) : super(AiChatState()) {
    _initializeChat();
  }

  void _initializeChat() {
    final welcomeMessage = ChatMessage(
      text: "👋 Hi! I'm your AI recipe assistant. I can help you create recipes through conversation. Just say 'I want to add a recipe' and I'll guide you through it step by step!",
      isUser: false,
    );
    state = state.copyWith(messages: [welcomeMessage]);
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

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

      print('🤖 AI Response: $aiResponse'); // Debug log

      // Check if response contains a recipe
      final recipe = _parseRecipeFromResponse(aiResponse);

      if (recipe != null) {
        print('✅ Recipe parsed successfully: ${recipe.name}'); // Debug log
        
        // Add the recipe to Hive through RecipeNotifier
        await _ref.read(recipeListProvider.notifier).addRecipe(recipe);
        
        print('💾 Recipe added to Hive'); // Debug log
        
        // Add success message
        final successMessage = ChatMessage(
          text: "✅ Perfect! I've created and saved '${recipe.name}' to your recipe collection.\n\n📋 Details:\n- Cook time: ${recipe.cookingTimeMinutes} minutes\n- Servings: ${recipe.servings}\n- Category: ${recipe.category}\n- Ingredients: ${recipe.ingredients.length}\n- Steps: ${recipe.instructions.length}\n\nYou can find it in your Recipes tab now! 🎉",
          isUser: false,
        );
        
        state = state.copyWith(
          messages: [...state.messages, successMessage],
          isLoading: false,
        );
      } else {
        // Add AI message (normal conversation)
        final aiChatMessage = ChatMessage(
          text: aiResponse,
          isUser: false,
        );

        state = state.copyWith(
          messages: [...state.messages, aiChatMessage],
          isLoading: false,
        );
      }
    } catch (e) {
      print('❌ Error: $e'); // Debug log
      
      state = state.copyWith(
        isLoading: false,
        error: 'Error: ${e.toString()}',
      );
      
      // Add error message to chat
      final errorMessage = ChatMessage(
        text: "😔 Sorry, I encountered an error. Please make sure:\n\n1. LM Studio is running\n2. A model is loaded\n3. Server is at localhost:1234\n\nError: ${e.toString()}",
        isUser: false,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
      );
    }
  }

  List<Map<String, String>> _buildConversationHistory() {
    final history = <Map<String, String>>[];
    
    // Add system prompt
    history.add({
      'role': 'system',
      'content': _aiService.systemPrompt,
    });

    // Add conversation messages (only last 10 to avoid token limit)
    final recentMessages = state.messages.length > 10 
        ? state.messages.sublist(state.messages.length - 10)
        : state.messages;

    for (var message in recentMessages) {
      history.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    return history;
  }

  Recipe? _parseRecipeFromResponse(String response) {
    try {
      print('🔍 Parsing response for recipe...'); // Debug log
      
      // Method 1: Try to find JSON in markdown code blocks
      final markdownJsonMatch = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```', multiLine: true).firstMatch(response);
      String? jsonString;
      
      if (markdownJsonMatch != null) {
        jsonString = markdownJsonMatch.group(1);
        print('📦 Found JSON in markdown block'); // Debug log
      } else {
        // Method 2: Try to find any JSON object
        final jsonMatch = RegExp(r'\{[\s\S]*?"action"\s*:\s*"CREATE_RECIPE"[\s\S]*?\}').firstMatch(response);
        if (jsonMatch != null) {
          jsonString = jsonMatch.group(0);
          print('📦 Found JSON in response'); // Debug log
        }
      }

      if (jsonString == null) {
        print('❌ No JSON found in response'); // Debug log
        return null;
      }

      print('📄 JSON String: $jsonString'); // Debug log

      // Parse JSON
      final data = jsonDecode(jsonString);

      // Check if it's a recipe creation action
      if (data['action'] != 'CREATE_RECIPE') {
        print('❌ Action is not CREATE_RECIPE'); // Debug log
        return null;
      }

      if (data['recipe'] == null) {
        print('❌ No recipe data found'); // Debug log
        return null;
      }

      final recipeData = data['recipe'];
      print('📝 Recipe data: $recipeData'); // Debug log

      // Validate and parse fields
      final name = recipeData['name']?.toString() ?? 'Untitled Recipe';
      final description = recipeData['description']?.toString() ?? '';
      
      // Parse cooking time (handle both int and string)
      final cookingTime = recipeData['cookingTimeMinutes'] is int 
          ? recipeData['cookingTimeMinutes'] 
          : int.tryParse(recipeData['cookingTimeMinutes']?.toString() ?? '30') ?? 30;
      
      // Parse servings (handle both int and string)
      final servings = recipeData['servings'] is int
          ? recipeData['servings']
          : int.tryParse(recipeData['servings']?.toString() ?? '2') ?? 2;
      
      final category = recipeData['category']?.toString() ?? 'Other';
      
      // Parse ingredients
      final ingredientsList = recipeData['ingredients'];
      final ingredients = ingredientsList is List
          ? ingredientsList.map((e) => e.toString()).toList()
          : <String>[];
      
      // Parse instructions
      final instructionsList = recipeData['instructions'];
      final instructions = instructionsList is List
          ? instructionsList.map((e) => e.toString()).toList()
          : <String>[];

      if (ingredients.isEmpty) {
        print('⚠️ No ingredients found'); // Debug log
        return null;
      }

      if (instructions.isEmpty) {
        print('⚠️ No instructions found'); // Debug log
        return null;
      }

      print('✅ Creating recipe: $name'); // Debug log

      // Create recipe
      final recipe = Recipe.create(
        name: name,
        description: description,
        ingredients: ingredients,
        instructions: instructions,
        cookingTimeMinutes: cookingTime,
        servings: servings,
        category: category,
      );

      print('✅ Recipe created successfully!'); // Debug log
      return recipe;
      
    } catch (e, stackTrace) {
      print('❌ Error parsing recipe: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log
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
  return AiChatNotifier(aiService, ref);
});