import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text;
    final pass = _passwordController.text;
    await ref.read(authStateProvider.notifier).login(email, pass);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login successful')),
    );
  }

  void _forgotPassword() async {
    final email = _emailController.text;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }
    await ref.read(authStateProvider.notifier).resetPassword(email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _login,
          child: const Text('Login'),
        ),
        TextButton(
          onPressed: _forgotPassword,
          child: const Text('Forgot Password?'),
        ),
      ],
    );
  }
}
