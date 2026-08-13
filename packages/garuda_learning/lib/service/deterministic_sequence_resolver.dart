/// Deterministic Sequence Resolver (TITAN-KO-017.0 P17).
///
/// Computes a deterministic, topological learning sequence for a set of
/// [LearningObjective]s based EXCLUSIVELY on explicitly declared prerequisites.
///
/// Determinism Guarantee:
/// When multiple objectives have no remaining unvisited prerequisites, tie-breaking
/// is strictly governed by `(sequenceIndex, id)`. Order is 100% reproducible.
library;

import '../domain/entities/learning_objective.dart';

class DeterministicSequenceResolver {
  /// Computes a deterministic learning sequence for the provided list of objectives.
  ///
  /// Throws [StateError] if a cyclic prerequisite dependency is encountered or
  /// if a declared prerequisite ID does not exist in the objective set.
  List<LearningObjective> resolveSequence(List<LearningObjective> objectives) {
    if (objectives.isEmpty) return const [];

    final objMap = <String, LearningObjective>{
      for (final obj in objectives) obj.id: obj,
    };

    // Calculate in-degree (number of prerequisites within this set)
    final inDegree = <String, int>{};
    final dependents = <String, List<String>>{};

    for (final obj in objectives) {
      inDegree[obj.id] = 0;
      dependents[obj.id] = [];
    }

    for (final obj in objectives) {
      for (final prereq in obj.prerequisites) {
        final prereqId = prereq.prerequisiteObjectiveId;

        // If prerequisite is outside the requested scope, skip if not mandatory, or fail if mandatory
        if (!objMap.containsKey(prereqId)) {
          throw StateError(
            'Cannot resolve sequence: Objective "${obj.id}" depends on unknown prerequisite "$prereqId"',
          );
        }

        inDegree[obj.id] = (inDegree[obj.id] ?? 0) + 1;
        dependents[prereqId]!.add(obj.id);
      }
    }

    // Queue of objectives ready to be learned (in-degree == 0)
    final readyList = objectives.where((o) => inDegree[o.id] == 0).toList();

    // Sort ready queue deterministically by sequenceIndex then id
    _sortObjectivesDeterministically(readyList);

    final orderedSequence = <LearningObjective>[];

    while (readyList.isNotEmpty) {
      // Pick the top ready objective
      final current = readyList.removeAt(0);
      orderedSequence.add(current);

      // Decrement in-degree for all dependents
      for (final depId in dependents[current.id]!) {
        inDegree[depId] = inDegree[depId]! - 1;
        if (inDegree[depId] == 0) {
          readyList.add(objMap[depId]!);
        }
      }

      // Re-sort ready queue deterministically
      _sortObjectivesDeterministically(readyList);
    }

    if (orderedSequence.length != objectives.length) {
      throw StateError(
        'Cyclic prerequisite dependency detected while resolving learning sequence.',
      );
    }

    return orderedSequence;
  }

  /// Sorts a mutable list of objectives deterministically by `(sequenceIndex, id)`.
  static void _sortObjectivesDeterministically(List<LearningObjective> list) {
    list.sort((a, b) {
      final seqCmp = a.sequenceIndex.compareTo(b.sequenceIndex);
      if (seqCmp != 0) return seqCmp;
      return a.id.compareTo(b.id);
    });
  }
}
