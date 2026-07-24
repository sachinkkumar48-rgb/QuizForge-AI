import '../repository/identity_repository.dart';

/// Clean Architecture Use Case for signing out the active session.
class SignOutUseCase {
  final IdentityRepository _repository;

  const SignOutUseCase(this._repository);

  /// Signs out and clears stored authentication session.
  Future<void> execute() {
    return _repository.signOut();
  }
}
