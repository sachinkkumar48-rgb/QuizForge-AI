import '../domain/entities/knowledge_object.dart';
import '../validators/validation_result.dart';

class KnowledgePipelineResult {
  final bool isSuccess;
  final KnowledgeObject? registeredObject;
  final int completedStage;
  final List<ValidationIssue> validationIssues;
  final String? errorMessage;
  final double durationMs;

  const KnowledgePipelineResult({
    required this.isSuccess,
    this.registeredObject,
    required this.completedStage,
    this.validationIssues = const [],
    this.errorMessage,
    required this.durationMs,
  });

  factory KnowledgePipelineResult.success({
    required KnowledgeObject object,
    required double durationMs,
  }) {
    return KnowledgePipelineResult(
      isSuccess: true,
      registeredObject: object,
      completedStage: 12,
      durationMs: durationMs,
    );
  }

  factory KnowledgePipelineResult.failure({
    required int stage,
    required String message,
    List<ValidationIssue> issues = const [],
    required double durationMs,
  }) {
    return KnowledgePipelineResult(
      isSuccess: false,
      completedStage: stage,
      errorMessage: message,
      validationIssues: issues,
      durationMs: durationMs,
    );
  }
}
