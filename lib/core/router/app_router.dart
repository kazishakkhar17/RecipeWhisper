import 'package:bli_flutter_recipewhisper/features/recipes/presentation/screens/cooking_timer_screen.dart';
import 'package:go_router/go_router.dart';
import '../../features/animations/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/recipes/presentation/screens/home_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/cooking-timer',
        builder: (context, state) {
          return const CookingTimerScreen(); // ✅ no recipe passed
        },
      ),
    ],
  );
}
