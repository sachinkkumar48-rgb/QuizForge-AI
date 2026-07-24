import '../models/revision_models.dart';
import '../repository/revision_repository.dart';

/// Clean Architecture Use Case for processing user recall attempt ratings (0-5)
/// and updating SM-2 spaced repetition intervals.
class ProcessRevisionAttemptUseCase {
  final RevisionRepository _repository;

  const ProcessRevisionAttemptUseCase(this._repository);

  /// Records a user's recall rating (0 to 5) for a revision item and returns the updated [RevisionItem].
  Future<RevisionItem> execute(String itemId, int qualityRating) {
    return _repository.recordRevisionAttempt(itemId, qualityRating);
  }
}
