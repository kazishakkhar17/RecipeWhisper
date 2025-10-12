import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<void> login(String email, String password) {
    return _dataSource.login(email, password);
  }

  @override
  Future<void> signup(String email, String password) {  // <-- add this
    return _dataSource.signup(email, password);
  }

  @override
  Future<void> logout() {
    return _dataSource.logout();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _dataSource.sendPasswordResetEmail(email);
  }
}
