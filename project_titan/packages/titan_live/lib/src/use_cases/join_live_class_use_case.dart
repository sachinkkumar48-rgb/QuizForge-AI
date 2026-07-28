import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for joining an active live class session.
class JoinLiveClassUseCase {
  final LiveClassRepository repository;

  const JoinLiveClassUseCase(this.repository);

  Future<Participant> execute(String sessionId, Participant participant) {
    return repository.joinSession(sessionId, participant);
  }
}
