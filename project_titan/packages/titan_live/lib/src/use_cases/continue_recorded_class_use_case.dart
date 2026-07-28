import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for retrieving and continuing a recorded live class.
class ContinueRecordedClassUseCase {
  final LiveClassRepository repository;

  const ContinueRecordedClassUseCase(this.repository);

  Future<Recording?> execute(String classId) async {
    final liveClass = await repository.getLiveClassById(classId);
    return liveClass?.recording;
  }
}
