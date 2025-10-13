import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    _navItem(context, 0, '🏠', 'Home', '/home'),
    _navItem(context, 1, '📖', 'Recipes', '/recipes'),
    _navItem(context, 2, '✨', 'AI', '/ai'),
    _navItem(context, 3, '👤', 'Profile', '/profile'),
    _navItem(context, 4, '⏰', 'Reminders', '/reminders'), // ← added
  ],
),

    );
  }

  Widget _navItem(BuildContext context, int index, String icon, String label, String route) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => GoRouter.of(context).go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 24)),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: isActive ? Colors.red : Colors.grey),
          ),
        ],
      ),
    );
  }
}
