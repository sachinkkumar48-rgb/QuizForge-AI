import '../auth/auth_provider.dart';
import '../models/user_session.dart';
import '../repository/identity_repository.dart';

/// Clean Architecture Use Case for signing in a user.
class SignInUseCase {
  final IdentityRepository _repository;

  const SignInUseCase(this._repository);

  /// Authenticates user credentials using the given provider.
  Future<UserSession> execute({
    required AuthProviderType providerType,
    Map<String, dynamic>? credentials,
  }) {
    return _repository.signIn(
      providerType: providerType,
      credentials: credentials,
    );
  }
}
