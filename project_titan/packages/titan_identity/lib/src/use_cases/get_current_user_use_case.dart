import '../models/user.dart';
import '../models/user_session.dart';
import '../repository/identity_repository.dart';

/// Clean Architecture Use Case for fetching current user profile and session.
class GetCurrentUserUseCase {
  final IdentityRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  /// Retrieves the active authenticated user profile.
  Future<User?> getUser() {
    return _repository.getCurrentUser();
  }

  /// Retrieves the active session instance.
  Future<UserSession?> getSession() {
    return _repository.getActiveSession();
  }
}
