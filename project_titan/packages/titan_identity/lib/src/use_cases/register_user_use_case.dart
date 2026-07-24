import '../auth/auth_provider.dart';
import '../models/user_session.dart';
import '../repository/identity_repository.dart';

/// Clean Architecture Use Case for registering a new user account.
class RegisterUserUseCase {
  final IdentityRepository _repository;

  const RegisterUserUseCase(this._repository);

  /// Registers a user using the specified provider and profile details.
  Future<UserSession> execute({
    required AuthProviderType providerType,
    required Map<String, dynamic> userDetails,
  }) {
    return _repository.register(
      providerType: providerType,
      userDetails: userDetails,
    );
  }
}
