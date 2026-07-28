import '../repository/live_class_repository.dart';

/// Use case for leaving a live class session.
class LeaveLiveClassUseCase {
  final LiveClassRepository repository;

  const LeaveLiveClassUseCase(this.repository);

  Future<bool> execute(String sessionId, String userId) {
    return repository.leaveSession(sessionId, userId);
  }
}
