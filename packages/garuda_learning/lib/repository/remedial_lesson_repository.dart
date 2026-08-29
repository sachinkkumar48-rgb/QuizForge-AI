/// Remedial Lesson Repository (TITAN-KO-025.0 P25).
///
/// Interface and in-memory implementation for storing and querying [RemedialLesson] models.
library;

import '../domain/entities/remedial_lesson.dart';

/// Abstract repository interface for storing and retrieving remedial micro-lessons.
abstract interface class RemedialLessonRepository {
  /// Retrieves a specific [RemedialLesson] by its canonical ID, or null if not found.
  Future<RemedialLesson?> getLesson(String lessonId);

  /// Retrieves all remedial lessons associated with a specific [objectiveId].
  /// Returns empty list if no lessons exist for the objective.
  Future<List<RemedialLesson>> getLessonsForObjective(String objectiveId);

  /// Persists or updates a single [RemedialLesson].
  Future<void> saveLesson(RemedialLesson lesson);

  /// Persists a batch of [RemedialLesson] entities.
  Future<void> saveAll(List<RemedialLesson> lessons);

  /// Retrieves all stored remedial lessons in the repository.
  Future<List<RemedialLesson>> getAll();

  /// Removes a lesson from storage by [lessonId].
  Future<void> deleteLesson(String lessonId);

  /// Clears all stored lessons (primarily for testing and cache reset).
  Future<void> clear();
}

/// Offline in-memory implementation of [RemedialLessonRepository].
class InMemoryRemedialLessonRepository implements RemedialLessonRepository {
  final Map<String, RemedialLesson> _lessons = {};

  InMemoryRemedialLessonRepository();

  @override
  Future<RemedialLesson?> getLesson(String lessonId) async {
    return _lessons[lessonId];
  }

  @override
  Future<List<RemedialLesson>> getLessonsForObjective(
      String objectiveId) async {
    final matching =
        _lessons.values.where((l) => l.objectiveId == objectiveId).toList()
          ..sort((a, b) {
            // Sort highest version first, tie-break by lessonId ASC
            final vCmp = b.version.compareTo(a.version);
            if (vCmp != 0) return vCmp;
            return a.lessonId.compareTo(b.lessonId);
          });
    return List.unmodifiable(matching);
  }

  @override
  Future<void> saveLesson(RemedialLesson lesson) async {
    _lessons[lesson.lessonId] = lesson;
  }

  @override
  Future<void> saveAll(List<RemedialLesson> lessons) async {
    for (final lesson in lessons) {
      _lessons[lesson.lessonId] = lesson;
    }
  }

  @override
  Future<List<RemedialLesson>> getAll() async {
    final list = _lessons.values.toList()
      ..sort((a, b) {
        final objCmp = a.objectiveId.compareTo(b.objectiveId);
        if (objCmp != 0) return objCmp;
        final vCmp = b.version.compareTo(a.version);
        if (vCmp != 0) return vCmp;
        return a.lessonId.compareTo(b.lessonId);
      });
    return List.unmodifiable(list);
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    _lessons.remove(lessonId);
  }

  @override
  Future<void> clear() async {
    _lessons.clear();
  }
}
