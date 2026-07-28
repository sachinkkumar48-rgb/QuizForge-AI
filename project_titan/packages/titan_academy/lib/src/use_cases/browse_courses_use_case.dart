import '../models/academy_models.dart';
import '../repository/academy_repository.dart';

/// Clean Architecture Use Case for browsing, searching, and filtering courses.
class BrowseCoursesUseCase {
  final AcademyRepository _repository;

  const BrowseCoursesUseCase(this._repository);

  /// Executes course retrieval with optional search and filter parameters.
  Future<List<Course>> execute({
    String? category,
    String? searchQuery,
    String? level,
  }) {
    return _repository.getCourses(
      category: category,
      searchQuery: searchQuery,
      level: level,
    );
  }
}
