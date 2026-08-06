import '../concepts/confidence_score.dart';
import '../concepts/mapping_method.dart';
import '../mappings/question_concept_mapping_model.dart';
import '../repositories/concept_repository_interface.dart';
import '../repositories/question_concept_repository_interface.dart';
import '../repository/pyq_repository_interface.dart';

class ConceptMappingService {
  final IPYQRepository pyqRepository;
  final IConceptRepository conceptRepository;
  final IQuestionConceptRepository mappingRepository;

  ConceptMappingService({
    required this.pyqRepository,
    required this.conceptRepository,
    required this.mappingRepository,
  });

  /// Maps a question to a concept with confidence scoring & auto-rejection handling.
  Future<QuestionConceptMapping> createMapping({
    required String questionId,
    required String conceptId,
    required double confidenceScore,
    required MappingMethod mappingMethod,
    String? remarks,
  }) async {
    final scoreObj = ConfidenceScore(confidenceScore);
    final status = scoreObj.isAccepted ? ReviewStatus.pending : ReviewStatus.rejected;

    final mapping = QuestionConceptMapping(
      questionId: questionId,
      conceptId: conceptId,
      confidenceScore: confidenceScore,
      mappingMethod: mappingMethod,
      reviewStatus: status,
      remarks: remarks ?? (scoreObj.isAccepted ? null : 'Auto-rejected due to low confidence score'),
    );

    await mappingRepository.saveMapping(mapping);

    // Synchronize Question model's conceptsTested list
    if (status != ReviewStatus.rejected) {
      final q = await pyqRepository.getQuestionById(questionId);
      if (q != null && !q.conceptsTested.contains(conceptId)) {
        final updatedTested = [...q.conceptsTested, conceptId];
        await pyqRepository.saveQuestion(q.copyWith(conceptsTested: updatedTested));
      }
    }

    return mapping;
  }

  /// Editorial review workflow.
  Future<QuestionConceptMapping?> reviewMapping({
    required String questionId,
    required String conceptId,
    required ReviewStatus newStatus,
    required String reviewerId,
    String? remarks,
  }) async {
    final mappings = await mappingRepository.getMappingsByQuestion(questionId);
    final existing = mappings.firstWhere(
      (m) => m.conceptId == conceptId,
      orElse: () => throw ArgumentError('Mapping not found for $questionId -> $conceptId'),
    );

    final updated = existing.copyWith(
      reviewStatus: newStatus,
      reviewedBy: reviewerId,
      reviewedAt: DateTime.now(),
      remarks: remarks ?? existing.remarks,
    );

    await mappingRepository.saveMapping(updated);
    return updated;
  }

  /// Retrieve accepted concept mappings for a specific question.
  Future<List<QuestionConceptMapping>> getAcceptedMappingsForQuestion(String questionId) async {
    final mappings = await mappingRepository.getMappingsByQuestion(questionId);
    return mappings.where((m) => m.reviewStatus != ReviewStatus.rejected).toList();
  }
}
