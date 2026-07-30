/// Abstract AuthRepository contract for Flutter identity and authentication.
abstract class AuthRepository {
  Future<void> register(String email, String password, {String? fullName});
  Future<void> login(String email, String password);
  Future<void> refresh();
  Future<void> logout();
  Future<void> getCurrentUser();
}
