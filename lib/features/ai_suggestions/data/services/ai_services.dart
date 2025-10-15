import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  final String baseUrl;
  final String apiKey;
  final String model;

  GroqService({
    this.baseUrl = 'https://api.groq.com/openai/v1',
    String? apiKey,
    String? model,
  })  : apiKey = apiKey ?? dotenv.env['GROQ_API_KEY'] ?? '',
        model = model ?? dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile'; // FIXED: Changed from llama3.3 to llama-3.3

  Future<String> sendMessage({required String message}) async {
    final conversationHistory = [
      {
        'role': 'system',
        'content': systemPrompt,
      },
      {
        'role': 'user',
        'content': message,
      },
    ];

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': conversationHistory,
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
    }
  }

  String get systemPrompt => '''You are a helpful recipe assistant AI. Your job is to create recipes based on user requests.

BEHAVIOR:
- When a user mentions a dish name (e.g., "pasta", "chocolate cake", "chicken curry"), automatically create a complete recipe for it
- When a user says "I want to add a recipe", ask them what dish they want
- Be helpful and conversational, but when creating a recipe, you MUST return valid JSON

RECIPE CREATION RULES:
When you decide to create a recipe, you MUST respond with ONLY a JSON object. No other text, no explanations, no greetings - JUST THE JSON.

The JSON MUST be in this EXACT format with NO trailing commas:

{
  "action": "CREATE_RECIPE",
  "recipe": {
    "name": "Recipe Name",
    "description": "A brief 1-2 sentence description",
    "cookingTimeMinutes": 30,
    "servings": 4,
    "category": "Dinner",
    "ingredients": [
      "2 cups flour",
      "1 cup sugar",
      "3 eggs"
    ],
    "instructions": [
      "Step 1: Do this",
      "Step 2: Do that",
      "Step 3: Final step"
    ]
  }
}

CRITICAL JSON REQUIREMENTS:
- Return ONLY the raw JSON object, nothing else
- NO markdown code blocks (no ```json or ```)
- NO explanatory text before or after the JSON
- NO trailing commas
- "cookingTimeMinutes" and "servings" MUST be numbers (not strings)
- "ingredients" and "instructions" MUST be arrays of strings
- "category" MUST be one of: Breakfast, Lunch, Dinner, Dessert, Snack, Other
- Each ingredient should include measurements (e.g., "2 cups flour" not just "flour")
- Each instruction should be a complete, clear step
''';
}