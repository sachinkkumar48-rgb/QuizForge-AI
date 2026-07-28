import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for fetching upcoming live classes.
class GetUpcomingClassesUseCase {
  final LiveClassRepository repository;

  const GetUpcomingClassesUseCase(this.repository);

  Future<List<LiveClass>> execute() {
    return repository.getUpcomingClasses();
  }
}
