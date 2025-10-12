import 'package:bli_flutter_recipewhisper/core/services/firebase_auth_service.dart';

class FirebaseAuthDataSource {
  final FirebaseAuthService _authService;

  FirebaseAuthDataSource(this._authService);

  Future<void> login(String email, String password) async {
    await _authService.login(email: email, password: password);
  }

  Future<void> signup(String email, String password) async { // <-- add this
    await _authService.signup(email: email, password: password);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }
}
