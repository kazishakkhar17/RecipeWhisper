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
          'max_tokens': 2000,
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

When a user wants to add a recipe:
1. Ask them for the recipe name
2. Ask for a brief description  
3. Ask for cooking time in minutes (must be a number)
4. Ask for number of servings (must be a number)
5. Ask for category (Breakfast, Lunch, Dinner, Dessert, Snack, or Other)
6. Ask for ingredients - they can list them separated by commas or line by line
7. Ask for cooking instructions - step by step

ASK ONE QUESTION AT A TIME. Be conversational and friendly.

When you have collected ALL the information, respond with ONLY this JSON format (no extra text before or after):
```json
{
  "action": "CREATE_RECIPE",
  "recipe": {
    "name": "Recipe Name Here",
    "description": "Brief description here",
    "cookingTimeMinutes": 30,
    "servings": 4,
    "category": "Dinner",
    "ingredients": ["2 cups flour", "1 cup sugar", "3 eggs"],
    "instructions": ["Preheat oven to 350F", "Mix ingredients", "Bake for 30 minutes"]
  }
}
```

IMPORTANT: 
- cookingTimeMinutes and servings MUST be numbers (not strings)
- ingredients and instructions MUST be arrays of strings
- When outputting the JSON, put it inside triple backticks with json tag
- Do not add any text before or after the JSON block

If the user asks about existing recipes or cooking tips, help them naturally.''';
}