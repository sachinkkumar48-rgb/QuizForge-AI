import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for stopping live session recording and persisting metadata.
class StopRecordingUseCase {
  final LiveClassRepository repository;

  const StopRecordingUseCase(this.repository);

  Future<Recording> execute({
    required String sessionId,
    required String recordingId,
    required String videoUrl,
    required int durationSeconds,
    required int fileSizeBytes,
    String? learningContentId,
  }) {
    final recording = Recording(
      id: recordingId,
      sessionId: sessionId,
      videoUrl: videoUrl,
      durationSeconds: durationSeconds,
      fileSizeBytes: fileSizeBytes,
      status: RecordingStatus.ready,
      createdAt: DateTime.now(),
      learningContentId: learningContentId,
    );
    return repository.saveRecordingMetadata(recording);
  }
}
