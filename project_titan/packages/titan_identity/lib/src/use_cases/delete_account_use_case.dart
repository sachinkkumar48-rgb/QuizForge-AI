import '../repository/identity_repository.dart';

/// Clean Architecture Use Case for permanently deleting user account and session data.
class DeleteAccountUseCase {
  final IdentityRepository _repository;

  const DeleteAccountUseCase(this._repository);

  /// Deletes user account and wipes local session data.
  Future<void> execute() {
    return _repository.deleteAccount();
  }
}
