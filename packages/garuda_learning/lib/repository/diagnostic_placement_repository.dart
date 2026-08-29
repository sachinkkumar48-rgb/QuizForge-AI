/// Diagnostic Placement Repository Interface (TITAN-KO-026.0 P26).
///
/// Contract for persisting and retrieving diagnostic placement evaluation results.
library;

import '../domain/entities/diagnostic_placement_result.dart';

abstract interface class DiagnosticPlacementRepository {
  /// Saves a diagnostic placement evaluation result.
  void saveResult(DiagnosticPlacementResult result);

  /// Retrieves the latest diagnostic placement result for a learner, or null.
  DiagnosticPlacementResult? getLatestResultForLearner(String learnerId);

  /// Retrieves all diagnostic placement results for a learner, in chronological order.
  List<DiagnosticPlacementResult> getResultsForLearner(String learnerId);

  /// Clears stored diagnostic results (used in test isolation).
  void clear();
}
