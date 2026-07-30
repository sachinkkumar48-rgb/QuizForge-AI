import '../domain/auth_repository.dart';

/// Concrete implementation placeholder of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<void> register(String email, String password, {String? fullName}) async {
    throw UnimplementedError("AuthRepositoryImpl register not implemented yet.");
  }

  @override
  Future<void> login(String email, String password) async {
    throw UnimplementedError("AuthRepositoryImpl login not implemented yet.");
  }

  @override
  Future<void> refresh() async {
    throw UnimplementedError("AuthRepositoryImpl refresh not implemented yet.");
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError("AuthRepositoryImpl logout not implemented yet.");
  }

  @override
  Future<void> getCurrentUser() async {
    throw UnimplementedError("AuthRepositoryImpl getCurrentUser not implemented yet.");
  }
}
