abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<void> signup(String email, String password); // <-- add this
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
}
