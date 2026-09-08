/// Faculty Content Repository (TITAN-KO-045.0 P45).
///
/// Interface and in-memory implementation providing version-tracked,
/// lifecycle-aware persistence for faculty-managed content items.
library;

import '../domain/entities/managed_content_item.dart';

/// Abstract repository interface for faculty-managed curriculum content.
abstract interface class FacultyContentRepository {
  /// Retrieves a specific managed content item by its canonical [id].
  /// If [version] is provided, retrieves that specific revision;
  /// otherwise retrieves the latest available version (draft or published).
  Future<ManagedContentItem?> getById(String id, {int? version});

  /// Retrieves the currently published version for [id], or null if unpublished.
  Future<ManagedContentItem?> getPublishedVersion(String id);

  /// Lists all managed items matching optional filter parameters.
  Future<List<ManagedContentItem>> getAll({
    String? examId,
    String? subjectId,
    String? topicId,
    String? objectiveId,
    ManagedContentType? contentType,
    ContentLifecycleStatus? status,
    String? authorId,
  });

  /// Retrieves all published content items associated with [objectiveId].
  Future<List<ManagedContentItem>> getPublishedContentForObjective(
      String objectiveId);

  /// Retrieves all published questions matching [topicName].
  Future<List<ManagedContentItem>> getPublishedQuestionsForTopic(
      String topicName);

  /// Persists a single managed content item revision.
  Future<void> save(ManagedContentItem item);

  /// Removes all versions of an item by [id].
  Future<void> delete(String id);

  /// Resets repository state (for testing).
  Future<void> clear();
}

/// Thread-safe in-memory implementation of [FacultyContentRepository].
class InMemoryFacultyContentRepository implements FacultyContentRepository {
  /// Storage map: contentId -> (version -> ManagedContentItem)
  final Map<String, Map<int, ManagedContentItem>> _store = {};

  InMemoryFacultyContentRepository();

  @override
  Future<ManagedContentItem?> getById(String id, {int? version}) async {
    final versions = _store[id];
    if (versions == null || versions.isEmpty) return null;

    if (version != null) {
      return versions[version];
    }

    // Return highest version
    final sortedKeys = versions.keys.toList()..sort();
    return versions[sortedKeys.last];
  }

  @override
  Future<ManagedContentItem?> getPublishedVersion(String id) async {
    final versions = _store[id];
    if (versions == null || versions.isEmpty) return null;

    final published = versions.values
        .where((i) => i.status == ContentLifecycleStatus.published)
        .toList()
      ..sort((a, b) => a.version.compareTo(b.version));

    if (published.isEmpty) return null;
    return published.last;
  }

  @override
  Future<List<ManagedContentItem>> getAll({
    String? examId,
    String? subjectId,
    String? topicId,
    String? objectiveId,
    ManagedContentType? contentType,
    ContentLifecycleStatus? status,
    String? authorId,
  }) async {
    final results = <ManagedContentItem>[];

    for (final versions in _store.values) {
      final ManagedContentItem? target;
      if (status != null) {
        final matching = versions.values
            .where((i) => i.status == status)
            .toList()
          ..sort((a, b) => a.version.compareTo(b.version));
        target = matching.isEmpty ? null : matching.last;
      } else {
        final sortedKeys = versions.keys.toList()..sort();
        target = versions[sortedKeys.last];
      }
      if (target == null) continue;

      if (examId != null &&
          target.examId.trim().toLowerCase() != examId.trim().toLowerCase()) {
        continue;
      }
      if (subjectId != null &&
          target.subjectId.trim().toLowerCase() !=
              subjectId.trim().toLowerCase()) {
        continue;
      }
      if (topicId != null &&
          target.topicId.trim().toLowerCase() != topicId.trim().toLowerCase()) {
        continue;
      }
      if (objectiveId != null && target.objectiveId != objectiveId) {
        continue;
      }
      if (contentType != null && target.contentType != contentType) {
        continue;
      }
      if (authorId != null && target.authorId != authorId) {
        continue;
      }

      results.add(target);
    }

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(results);
  }

  @override
  Future<List<ManagedContentItem>> getPublishedContentForObjective(
      String objectiveId) async {
    final publishedItems = <ManagedContentItem>[];

    for (final versions in _store.values) {
      final matching = versions.values
          .where((item) =>
              item.status == ContentLifecycleStatus.published &&
              item.objectiveId == objectiveId)
          .toList()
        ..sort((a, b) => a.version.compareTo(b.version));
      if (matching.isNotEmpty) {
        publishedItems.add(matching.last);
      }
    }

    publishedItems.sort((a, b) => b.version.compareTo(a.version));
    return List.unmodifiable(publishedItems);
  }

  @override
  Future<List<ManagedContentItem>> getPublishedQuestionsForTopic(
      String topicName) async {
    final tLower = topicName.trim().toLowerCase();
    final questions = <ManagedContentItem>[];

    for (final versions in _store.values) {
      final matching = versions.values
          .where((item) =>
              item.status == ContentLifecycleStatus.published &&
              item.contentType == ManagedContentType.question &&
              (item.topicId.trim().toLowerCase() == tLower ||
                  item.objectiveId.trim().toLowerCase() == tLower))
          .toList()
        ..sort((a, b) => a.version.compareTo(b.version));
      if (matching.isNotEmpty) {
        questions.add(matching.last);
      }
    }

    questions.sort((a, b) => b.version.compareTo(a.version));
    return List.unmodifiable(questions);
  }

  @override
  Future<void> save(ManagedContentItem item) async {
    final versions =
        _store.putIfAbsent(item.id, () => <int, ManagedContentItem>{});
    versions[item.version] = item;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
