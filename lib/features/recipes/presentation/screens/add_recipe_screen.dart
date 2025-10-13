import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';
import 'package:bli_flutter_recipewhisper/core/widgets/app_button.dart';
import '../../domain/entities/recipe.dart';
import '../providers/recipe_provider.dart';

class AddRecipeScreen extends ConsumerStatefulWidget {
  final Recipe? recipe; // null for add, Recipe for edit

  const AddRecipeScreen({super.key, this.recipe});

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _cookingTimeController;
  late TextEditingController _servingsController;
  late TextEditingController _categoryController;

  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _instructionControllers = [];

  bool get isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _descriptionController = TextEditingController(text: widget.recipe?.description ?? '');
    _cookingTimeController = TextEditingController(
      text: widget.recipe?.cookingTimeMinutes.toString() ?? '',
    );
    _servingsController = TextEditingController(
      text: widget.recipe?.servings.toString() ?? '',
    );
    _categoryController = TextEditingController(text: widget.recipe?.category ?? '');

    // Initialize ingredients
    if (widget.recipe != null) {
      for (var ingredient in widget.recipe!.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ingredient));
      }
    } else {
      _addIngredientField();
    }

    // Initialize instructions
    if (widget.recipe != null) {
      for (var instruction in widget.recipe!.instructions) {
        _instructionControllers.add(TextEditingController(text: instruction));
      }
    } else {
      _addInstructionField();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    _categoryController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredientField() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _addInstructionField() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstructionField(int index) {
    setState(() {
      _instructionControllers[index].dispose();
      _instructionControllers.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final instructions = _instructionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('add_ingredient'))),
      );
      return;
    }

    if (instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('add_instruction'))),
      );
      return;
    }

    try {
      if (isEditing) {
        // Update existing recipe
        final updatedRecipe = widget.recipe!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          ingredients: ingredients,
          instructions: instructions,
          cookingTimeMinutes: int.parse(_cookingTimeController.text.trim()),
          servings: int.parse(_servingsController.text.trim()),
          category: _categoryController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await ref.read(recipeListProvider.notifier).updateRecipe(updatedRecipe);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('recipe_updated'))),
        );
      } else {
        // Create new recipe
        final newRecipe = Recipe.create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          ingredients: ingredients,
          instructions: instructions,
          cookingTimeMinutes: int.parse(_cookingTimeController.text.trim()),
          servings: int.parse(_servingsController.text.trim()),
          category: _categoryController.text.trim().isEmpty 
              ? 'Other' 
              : _categoryController.text.trim(),
        );
        await ref.read(recipeListProvider.notifier).addRecipe(newRecipe);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('recipe_added'))),
        );
      }
      GoRouter.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(isEditing ? 'edit_recipe' : 'add_recipe')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.tr('recipe_name'),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter recipe name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: context.tr('recipe_description'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cooking time and servings row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cookingTimeController,
                    decoration: InputDecoration(
                      labelText: '${context.tr('cooking_time')} (${context.tr('minutes')})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: InputDecoration(
                      labelText: context.tr('servings'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: context.tr('category'),
                border: const OutlineInputBorder(),
                hintText: 'e.g., Breakfast, Lunch, Dinner',
              ),
            ),
            const SizedBox(height: 24),

            // Ingredients section
            Text(
              context.tr('ingredients'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._ingredientControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '${context.tr('enter_ingredient')} ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeIngredientField(index),
                    ),
                  ],
                ),
              );
            }).toList(),
            TextButton.icon(
              onPressed: _addIngredientField,
              icon: const Icon(Icons.add),
              label: Text(context.tr('add_ingredient')),
            ),
            const SizedBox(height: 24),

            // Instructions section
            Text(
              context.tr('instructions'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._instructionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '${context.tr('step')} ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeInstructionField(index),
                    ),
                  ],
                ),
              );
            }).toList(),
            TextButton.icon(
              onPressed: _addInstructionField,
              icon: const Icon(Icons.add),
              label: Text(context.tr('add_instruction')),
            ),
            const SizedBox(height: 32),

            // Save button
            AppButton(
              text: context.tr('save'),
              onPressed: _saveRecipe,
            ),
          ],
        ),
      ),
    );
  }
}