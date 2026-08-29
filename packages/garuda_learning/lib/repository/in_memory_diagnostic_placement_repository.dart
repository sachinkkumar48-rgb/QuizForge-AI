/// In-Memory Diagnostic Placement Repository (TITAN-KO-026.0 P26).
///
/// Deterministic in-memory storage for diagnostic placement evaluation results.
library;

import '../domain/entities/diagnostic_placement_result.dart';
import 'diagnostic_placement_repository.dart';

class InMemoryDiagnosticPlacementRepository
    implements DiagnosticPlacementRepository {
  final Map<String, List<DiagnosticPlacementResult>> _resultsByLearner = {};

  @override
  void saveResult(DiagnosticPlacementResult result) {
    final list = _resultsByLearner.putIfAbsent(result.learnerId, () => []);
    list.add(result);
    list.sort((a, b) => a.evaluatedAt.compareTo(b.evaluatedAt));
  }

  @override
  DiagnosticPlacementResult? getLatestResultForLearner(String learnerId) {
    final list = _resultsByLearner[learnerId];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  @override
  List<DiagnosticPlacementResult> getResultsForLearner(String learnerId) {
    final list = _resultsByLearner[learnerId];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  @override
  void clear() {
    _resultsByLearner.clear();
  }
}
