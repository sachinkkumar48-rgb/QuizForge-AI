import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for scheduling a new live class session.
class ScheduleLiveClassUseCase {
  final LiveClassRepository repository;

  const ScheduleLiveClassUseCase(this.repository);

  Future<LiveClass> execute(LiveClass liveClass) {
    return repository.scheduleClass(liveClass);
  }
}
