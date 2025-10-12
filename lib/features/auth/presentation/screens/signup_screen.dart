import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'package:bli_flutter_recipewhisper/core/widgets/app_button.dart';
import 'package:bli_flutter_recipewhisper/core/widgets/app_text_field.dart';


class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
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
  text: 'Signup',
  onPressed: () async {
    try {
      await ref.read(authStateProvider.notifier).signup( // <-- change login to signup
            emailController.text.trim(),
            passwordController.text.trim(),
          );

      // Navigate to home on success
      ref.read(authStateProvider).when(
            data: (_) => GoRouter.of(context).go('/home'),
            loading: () {},
            error: (error, _) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Signup failed: $error')),
              );
            },
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup error: $e')),
      );
    }
  },
),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                GoRouter.of(context).go('/login');
              },
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
