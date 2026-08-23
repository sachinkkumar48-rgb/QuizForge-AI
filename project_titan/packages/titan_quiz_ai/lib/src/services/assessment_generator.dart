import '../models/assessment_generation_request.dart';
import '../models/assessment_generation_result.dart';

/// Engine-independent interface for smart assessment generation in Project TITAN.
abstract interface class AssessmentGenerator {
  /// Generates a validated [AssessmentGenerationResult] from an [AssessmentGenerationRequest].
  Future<AssessmentGenerationResult> generateAssessment(
    AssessmentGenerationRequest request,
  );
}
