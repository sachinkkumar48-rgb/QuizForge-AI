/// Learner Repository (TITAN-KO-018.0 P18).
///
/// Interface and in-memory implementation for learner profile persistence.
library;

import '../domain/entities/learner.dart';

abstract interface class LearnerRepository {
  /// Saves or updates a learner profile.
  void save(Learner learner);

  /// Retrieves a learner by ID, or null if not found.
  Learner? getById(String id);

  /// Retrieves all registered learners in deterministic order.
  List<Learner> getAll();

  /// Whether a learner exists by ID.
  bool exists(String id);

  /// Removes all stored learners (for testing).
  void clear();
}

class InMemoryLearnerRepository implements LearnerRepository {
  final Map<String, Learner> _learners = {};

  InMemoryLearnerRepository([List<Learner>? initialLearners]) {
    if (initialLearners != null) {
      for (final l in initialLearners) {
        save(l);
      }
    }
  }

  @override
  void save(Learner learner) {
    _learners[learner.id] = learner;
  }

  @override
  Learner? getById(String id) {
    return _learners[id];
  }

  @override
  List<Learner> getAll() {
    final list = _learners.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }

  @override
  bool exists(String id) {
    return _learners.containsKey(id);
  }

  @override
  void clear() {
    _learners.clear();
  }
}
