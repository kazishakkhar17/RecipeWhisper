import 'package:hive/hive.dart';

part 'recipe.g.dart';

@HiveType(typeId: 0)
class Recipe {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<String> ingredients;

  @HiveField(4)
  final List<String> instructions;

  @HiveField(5)
  final int cookingTimeMinutes;

  @HiveField(6)
  final int servings;

  @HiveField(7)
  final String category;

  @HiveField(8)
  final String? imageUrl;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime? updatedAt;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.cookingTimeMinutes,
    required this.servings,
    this.category = 'Other',
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating new recipe
  factory Recipe.create({
    required String name,
    required String description,
    required List<String> ingredients,
    required List<String> instructions,
    required int cookingTimeMinutes,
    required int servings,
    String category = 'Other',
    String? imageUrl,
  }) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      ingredients: ingredients,
      instructions: instructions,
      cookingTimeMinutes: cookingTimeMinutes,
      servings: servings,
      category: category,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
  }

  // CopyWith method for updates
  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    int? cookingTimeMinutes,
    int? servings,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
      servings: servings ?? this.servings,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'cookingTimeMinutes': cookingTimeMinutes,
      'servings': servings,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      ingredients: List<String>.from(map['ingredients']),
      instructions: List<String>.from(map['instructions']),
      cookingTimeMinutes: map['cookingTimeMinutes'],
      servings: map['servings'],
      category: map['category'] ?? 'Other',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, servings: $servings, time: ${cookingTimeMinutes}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}