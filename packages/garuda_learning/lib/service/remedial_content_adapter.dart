/// Remedial Content Generation Adapter Contract (TITAN-KO-025.0 P25).
///
/// Abstract adapter boundary defining contracts for optional external or AI-assisted
/// content generation engines.
///
/// Architectural Invariants:
/// - Core garuda_learning domain logic NEVER depends on this adapter.
/// - LLMs or external generator tools must remain optional plugins behind this interface.
/// - Any lesson produced by an AI-assisted adapter MUST be stamped with [ContentOrigin.aiGenerated].
library;

import '../domain/entities/learning_objective.dart';
import '../domain/entities/remedial_lesson.dart';
import '../domain/entities/source_reference.dart';

/// Contract for optional content-generation adapters.
abstract interface class RemedialContentAdapter {
  /// Synthesizes or extracts a structured [RemedialLesson] for a target [objective].
  ///
  /// Must tag generated content with [ContentOrigin.aiGenerated] to preserve epistemic safety.
  Future<RemedialLesson> generateLesson({
    required LearningObjective objective,
    List<SourceReference> sourceReferences = const [],
    int estimatedMinutes = 10,
    DateTime? authoredAt,
  });
}
