import 'package:bli_flutter_recipewhisper/core/widgets/app_button.dart';
import 'package:bli_flutter_recipewhisper/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTextField(controller: emailController, hintText: 'Email'),
            const SizedBox(height: 16),
            AppTextField(
              controller: passwordController,
              hintText: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Login',
              onPressed: () async {
                await ref.read(authStateProvider.notifier).login(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                // Navigate on success, show error on failure
                ref.read(authStateProvider).when(
                  data: (_) => GoRouter.of(context).go('/home'),
                  loading: () {},
                  error: (error, _) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $error')),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).resetPassword(emailController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent')),
                );
              },
              child: const Text('Forgot Password?'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                GoRouter.of(context).go('/signup');
              },
              child: const Text("Don't have an account? Signup"),
            ),
          ],
        ),
      ),
    );
  }
}
