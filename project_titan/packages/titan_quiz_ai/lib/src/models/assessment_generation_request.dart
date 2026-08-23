import 'package:meta/meta.dart';
import 'assessment_blueprint.dart';
import 'assessment_cancellation_token.dart';
import 'assessment_source.dart';

/// Immutable domain model representing a complete request to generate an assessment.
@immutable
class AssessmentGenerationRequest {
  final AssessmentBlueprint blueprint;
  final List<AssessmentSource> sources;
  final AssessmentCancellationToken? cancellationToken;

  AssessmentGenerationRequest({
    required this.blueprint,
    required List<AssessmentSource> sources,
    this.cancellationToken,
  }) : sources = List.unmodifiable(sources);

  const AssessmentGenerationRequest.constRequest({
    required this.blueprint,
    required this.sources,
    this.cancellationToken,
  });

  /// Total estimated tokens across all supplied sources.
  int get totalSourceTokens =>
      sources.fold(0, (sum, src) => sum + src.tokenEstimate);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentGenerationRequest &&
          runtimeType == other.runtimeType &&
          blueprint == other.blueprint &&
          sources.length == other.sources.length;

  @override
  int get hashCode => Object.hash(blueprint, Object.hashAll(sources));
}
