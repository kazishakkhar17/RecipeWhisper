import 'package:bli_flutter_recipewhisper/features/auth/presentation/screens/profile_screen.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bli_flutter_recipewhisper/features/auth/presentation/providers/auth_provider.dart';

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
          child: Text(
            context.tr('popular_recipes'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Recipe cards list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _recipeCard('Spicy Thai Basil Chicken', '🗡'),
              _recipeCard('Avocado Toast', '🥑'),
              _recipeCard('Chocolate Cake', '🍰'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recipeCard(String title, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 36)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        '${context.tr('recipes')} Screen',
        style: const TextStyle(fontSize: 20),
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