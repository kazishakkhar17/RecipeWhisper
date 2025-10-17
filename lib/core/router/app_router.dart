import 'package:bli_flutter_recipewhisper/features/recipes/presentation/screens/cooking_timer_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/animations/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/recipes/presentation/screens/home_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup';
      
      // If on splash screen, let it proceed (it will handle navigation)
      if (state.matchedLocation == '/') {
        return null;
      }
      
      // If user is not logged in and not on auth screens, go to login
      if (user == null && !isLoggingIn) {
        return '/login';
      }
      
      // If user is logged in and on auth screens, go to home
      if (user != null && isLoggingIn) {
        return '/home';
      }
      
      return null; // No redirect needed
    },
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
          return const CookingTimerScreen();
        },
      ),
    ],
  );
}