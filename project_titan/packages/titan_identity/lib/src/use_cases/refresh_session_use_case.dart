import '../models/user_session.dart';
import '../repository/identity_repository.dart';

/// Clean Architecture Use Case for refreshing an active authentication session.
class RefreshSessionUseCase {
  final IdentityRepository _repository;

  const RefreshSessionUseCase(this._repository);

  /// Triggers session token refresh.
  Future<UserSession> execute() {
    return _repository.refreshSession();
  }
}
