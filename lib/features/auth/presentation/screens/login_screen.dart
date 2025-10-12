import 'package:bli_flutter_recipewhisper/core/widgets/app_button.dart';
import 'package:bli_flutter_recipewhisper/core/widgets/app_text_field.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final orangeGradient = const LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Accent icon circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: orangeGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '👨‍🍳',
                      style: TextStyle(fontSize: 42),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  context.tr('app_name'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  "Your personal cooking companion",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // Form card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: emailController,
                        hintText: context.tr('email'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: passwordController,
                        hintText: context.tr('password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: context.tr('login'),
                        onPressed: () async {
                          await ref
                              .read(authStateProvider.notifier)
                              .login(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              );

                          ref.read(authStateProvider).when(
                            data: (_) => GoRouter.of(context).go('/home'),
                            loading: () {},
                            error: (error, _) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${context.tr('login_failed')}: $error'),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          if (emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('enter_email_first')),
                              ),
                            );
                            return;
                          }
                          await ref
                              .read(authStateProvider.notifier)
                              .resetPassword(
                                emailController.text.trim(),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('password_reset_sent')),
                            ),
                          );
                        },
                        child: Text(
                          context.tr('forgot_password'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          GoRouter.of(context).go('/signup');
                        },
                        child: Text(
                          context.tr('dont_have_account'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}