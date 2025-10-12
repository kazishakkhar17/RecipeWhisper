import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';

// ONLY declare it here; DO NOT redeclare in main.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.login(email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signup(String email, String password) async { // <-- added
    state = const AsyncValue.loading();
    try {
      await _repo.signup(email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repo.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
