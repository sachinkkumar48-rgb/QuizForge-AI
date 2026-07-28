import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for starting live session recording.
class StartRecordingUseCase {
  final LiveClassRepository repository;

  const StartRecordingUseCase(this.repository);

  Future<Recording> execute(String sessionId) {
    final now = DateTime.now();
    final recording = Recording(
      id: 'rec_${now.millisecondsSinceEpoch}',
      sessionId: sessionId,
      durationSeconds: 0,
      status: RecordingStatus.recording,
      createdAt: now,
    );
    return repository.saveRecordingMetadata(recording);
  }
}
