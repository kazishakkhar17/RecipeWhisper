import 'dart:convert';
import 'package:http/http.dart' as http;

class LMStudioService {
  // Change this to your LM Studio server URL
  // Default LM Studio runs on http://localhost:1234
  final String baseUrl;
  
  LMStudioService({this.baseUrl = 'http://localhost:1234'});

  /// Send a message to LM Studio and get AI response
  Future<String> sendMessage({
    required String message,
    required List<Map<String, String>> conversationHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': conversationHistory,
          'temperature': 0.7,
          'max_tokens': 1000,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to LM Studio: $e');
    }
  }

  /// System prompt for recipe assistant
  String get systemPrompt => '''You are a helpful recipe assistant. Your job is to help users create recipes through natural conversation.

When a user wants to add a recipe, ask them questions one at a time:
1. Recipe name
2. Brief description
3. Cooking time in minutes
4. Number of servings
5. Category (Breakfast, Lunch, Dinner, Dessert, Snack, etc.)
6. Ingredients (ask for them one by one or as a list)
7. Instructions (step by step)

When you have all the information, respond with a JSON object in this EXACT format:
{
  "action": "CREATE_RECIPE",
  "recipe": {
    "name": "Recipe Name",
    "description": "Brief description",
    "cookingTimeMinutes": 30,
    "servings": 4,
    "category": "Dinner",
    "ingredients": ["ingredient 1", "ingredient 2", "ingredient 3"],
    "instructions": ["step 1", "step 2", "step 3"]
  }
}

Be friendly, helpful, and conversational. If the user asks about existing recipes or cooking tips, help them with that too.''';
}