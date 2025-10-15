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
      text: "👋 Hi! I'm your AI recipe assistant. Just tell me what dish you want (e.g., 'spaghetti bolognese', 'chocolate chip cookies'), and I'll create a complete recipe for you instantly!\n\nYou can also ask me for cooking tips, meal suggestions, or help with meal planning. 🍳",
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

      print('🤖 Raw AI Response:\n$aiResponse\n---END RESPONSE---');

      // Try to parse recipe from response
      final recipe = _parseRecipeFromResponse(aiResponse);

      if (recipe != null) {
        print('✅ Recipe parsed successfully: ${recipe.name}');
        
        // Add the recipe to Hive through RecipeNotifier
        await _ref.read(recipeListProvider.notifier).addRecipe(recipe);
        
        print('💾 Recipe added to Hive');
        
        // Add success message (NOT the JSON)
        final successMessage = ChatMessage(
          text: "✅ Perfect! I've created and saved '${recipe.name}' to your recipe collection.\n\n📋 Summary:\n• Cook time: ${recipe.cookingTimeMinutes} minutes\n• Servings: ${recipe.servings}\n• Category: ${recipe.category}\n• Ingredients: ${recipe.ingredients.length}\n• Steps: ${recipe.instructions.length}\n\nYou can find it in your Recipes tab now! 🎉\n\nWant to create another recipe? Just tell me what you'd like to make!",
          isUser: false,
        );
        
        state = state.copyWith(
          messages: [...state.messages, successMessage],
          isLoading: false,
        );
        
        return recipe;
      } else {
        // Check if response looks like JSON but failed to parse
        if (aiResponse.trim().startsWith('{') && aiResponse.contains('CREATE_RECIPE')) {
          print('⚠️ Response looks like JSON but failed to parse. Showing error.');
          final errorMessage = ChatMessage(
            text: "🔧 I created a recipe, but there was a formatting issue. Let me try again. Please repeat your request.",
            isUser: false,
          );
          
          state = state.copyWith(
            messages: [...state.messages, errorMessage],
            isLoading: false,
          );
          return null;
        }
        
        // Add AI message (normal conversation)
        final aiChatMessage = ChatMessage(
          text: aiResponse,
          isUser: false,
        );

        state = state.copyWith(
          messages: [...state.messages, aiChatMessage],
          isLoading: false,
        );
        
        return null;
      }
    } catch (e) {
      print('❌ Error: $e');
      
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

    // Add conversation messages (only last 8 to avoid token limit)
    final recentMessages = state.messages.length > 8 
        ? state.messages.sublist(state.messages.length - 8)
        : state.messages;

    for (var message in recentMessages) {
      // Skip system messages (welcome message, success messages, errors)
      if (!message.isUser && message.text.startsWith('👋')) continue;
      if (!message.isUser && message.text.startsWith('✅')) continue;
      if (!message.isUser && message.text.startsWith('😔')) continue;
      if (!message.isUser && message.text.startsWith('🔧')) continue;
      
      history.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    return history;
  }

  Recipe? _parseRecipeFromResponse(String response) {
    try {
      print('🔍 Parsing response for recipe...');
      
      // Remove all markdown code blocks and extra whitespace
      String cleanResponse = response
          .trim()
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .replaceAll(RegExp(r'^\s+', multiLine: true), '') // Remove leading whitespace from each line
          .trim();
      
      print('🧹 Cleaned response length: ${cleanResponse.length}');
      
      // Find the JSON object - look for the opening and closing braces
      final startIndex = cleanResponse.indexOf('{');
      final lastIndex = cleanResponse.lastIndexOf('}');
      
      if (startIndex == -1 || lastIndex == -1 || startIndex >= lastIndex) {
        print('❌ No valid JSON object found');
        return null;
      }
      
      // Extract just the JSON object
      String jsonString = cleanResponse.substring(startIndex, lastIndex + 1);
      
      // Additional cleanup - remove any control characters and normalize whitespace
      jsonString = jsonString
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control characters
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
          .replaceAll(', }', '}') // Fix trailing commas before closing braces
          .replaceAll(', ]', ']'); // Fix trailing commas before closing brackets
      
      print('📦 Extracted JSON (first 200 chars): ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');
      
      // Try to parse the JSON
      dynamic data;
      try {
        data = jsonDecode(jsonString);
      } catch (e) {
        print('❌ JSON decode failed: $e');
        print('📄 Failed JSON string: $jsonString');
        
        // Try one more time with even more aggressive cleaning
        jsonString = _aggressiveJsonCleanup(jsonString);
        print('🔄 Trying again with aggressive cleanup...');
        data = jsonDecode(jsonString);
      }

      // Validate structure
      if (data is! Map<String, dynamic>) {
        print('❌ Parsed data is not a Map');
        return null;
      }

      if (data['action'] != 'CREATE_RECIPE') {
        print('❌ Action is not CREATE_RECIPE, got: ${data['action']}');
        return null;
      }

      if (data['recipe'] == null) {
        print('❌ No recipe data found');
        return null;
      }

      final recipeData = data['recipe'] as Map<String, dynamic>;
      print('📝 Recipe data keys: ${recipeData.keys.toList()}');

      // Extract and validate fields
      final name = recipeData['name']?.toString().trim() ?? 'Untitled Recipe';
      final description = recipeData['description']?.toString().trim() ?? 'A delicious recipe';
      
      // Parse cooking time
      int cookingTime = 30;
      if (recipeData['cookingTimeMinutes'] != null) {
        if (recipeData['cookingTimeMinutes'] is int) {
          cookingTime = recipeData['cookingTimeMinutes'];
        } else if (recipeData['cookingTimeMinutes'] is double) {
          cookingTime = (recipeData['cookingTimeMinutes'] as double).toInt();
        } else {
          cookingTime = int.tryParse(recipeData['cookingTimeMinutes'].toString()) ?? 30;
        }
      }
      
      // Parse servings
      int servings = 4;
      if (recipeData['servings'] != null) {
        if (recipeData['servings'] is int) {
          servings = recipeData['servings'];
        } else if (recipeData['servings'] is double) {
          servings = (recipeData['servings'] as double).toInt();
        } else {
          servings = int.tryParse(recipeData['servings'].toString()) ?? 4;
        }
      }
      
      final category = recipeData['category']?.toString().trim() ?? 'Other';
      
      // Parse ingredients
      List<String> ingredients = [];
      if (recipeData['ingredients'] is List) {
        ingredients = (recipeData['ingredients'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      
      // Parse instructions
      List<String> instructions = [];
      if (recipeData['instructions'] is List) {
        instructions = (recipeData['instructions'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // Validate required fields
      if (name.isEmpty || name == 'Untitled Recipe') {
        print('⚠️ Recipe name is empty or default');
        return null;
      }

      if (ingredients.isEmpty) {
        print('⚠️ No ingredients found');
        return null;
      }

      if (instructions.isEmpty) {
        print('⚠️ No instructions found');
        return null;
      }

      print('✅ Creating recipe: $name with ${ingredients.length} ingredients and ${instructions.length} steps');

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

      print('✅ Recipe created successfully!');
      return recipe;
      
    } catch (e, stackTrace) {
      print('❌ Error parsing recipe: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Aggressive JSON cleanup for malformed responses
  String _aggressiveJsonCleanup(String json) {
    return json
        .replaceAll(RegExp(r',\s*}'), '}') // Remove trailing commas before }
        .replaceAll(RegExp(r',\s*]'), ']') // Remove trailing commas before ]
        .replaceAll(RegExp(r'}\s*{'), '},{') // Fix adjacent objects
        .replaceAll(RegExp(r']\s*\['), '],[') // Fix adjacent arrays
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // Remove multiple newlines
        .replaceAll(RegExp(r'\r'), '') // Remove carriage returns
        .trim();
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