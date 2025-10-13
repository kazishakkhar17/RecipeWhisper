import 'package:bli_flutter_recipewhisper/features/auth/presentation/screens/profile_screen.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';
import 'package:bli_flutter_recipewhisper/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bli_flutter_recipewhisper/features/auth/presentation/providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';
import 'add_recipe_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    const HomeContent(),
    const RecipesScreen(),
    const AiScreen(),
    const ProfileScreen(),
    const ReminderScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF6B6B),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Text('🏠', style: TextStyle(fontSize: 24)),
            label: context.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Text('📖', style: TextStyle(fontSize: 24)),
            label: context.tr('recipes'),
          ),
          BottomNavigationBarItem(
            icon: const Text('✨', style: TextStyle(fontSize: 24)),
            label: context.tr('ai'),
          ),
          BottomNavigationBarItem(
            icon: const Text('👤', style: TextStyle(fontSize: 24)),
            label: context.tr('profile'),
          ),
          BottomNavigationBarItem(
  icon: const Text('⏰', style: TextStyle(fontSize: 24)),
  label: context.tr('reminders'),
),

        ],
      ),
    );
  }
}

// -------------------------- Screens ----------------------------

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning';
    if (hour < 17) return 'good_afternoon';
    return 'good_evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipeListProvider);
    
    return Column(
      children: [
        // Top gradient bar with greeting
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(_getGreeting()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.tr('what_to_cook'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  GoRouter.of(context).go('/login');
                },
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: TextField(
            onChanged: (value) {
              ref.read(recipeSearchProvider.notifier).state = value;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: context.tr('search_recipes'),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('popular_recipes'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              recipesAsync.when(
                data: (recipes) => Text(
                  '${recipes.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // Recipe list
        Expanded(
          child: recipesAsync.when(
            data: (recipes) {
              final searchQuery = ref.watch(recipeSearchProvider);
              final filteredRecipes = searchQuery.isEmpty
                  ? recipes
                  : recipes.where((recipe) {
                      final query = searchQuery.toLowerCase();
                      return recipe.name.toLowerCase().contains(query) ||
                             recipe.description.toLowerCase().contains(query) ||
                             recipe.category.toLowerCase().contains(query);
                    }).toList();

              if (filteredRecipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('no_recipes'),
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('add_your_first'),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredRecipes.length,
                itemBuilder: (context, index) {
                  return RecipeCard(recipe: filteredRecipes[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(filteredRecipesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('recipes')),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                ref.read(recipeSearchProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('search_recipes'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          
          // Recipe list
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('no_recipes'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(recipe: recipes[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddRecipeScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AiScreen extends ConsumerWidget {
  const AiScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        '${context.tr('ai')} Screen',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}