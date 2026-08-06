import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('ConceptMappingService Tests', () {
    late OfflinePYQRepository pyqRepo;
    late OfflineConceptRepository conceptRepo;
    late OfflineQuestionConceptRepository mappingRepo;
    late ConceptMappingService mappingService;

    setUp(() async {
      pyqRepo = OfflinePYQRepository();
      conceptRepo = OfflineConceptRepository();
      mappingRepo = OfflineQuestionConceptRepository();
      mappingService = ConceptMappingService(
        pyqRepository: pyqRepo,
        conceptRepository: conceptRepo,
        mappingRepository: mappingRepo,
      );

      final source = QuestionSource(
        sourceType: SourceType.editorialEntry,
        publisher: 'Test',
        retrievedDate: DateTime.now(),
        checksum: '111',
      );

      final q = Question(
        id: 'Q_MAP_1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        originalQuestion: 'Question text',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Exp',
        source: source,
      );

      await pyqRepo.saveQuestion(q);
    });

    test('createMapping applies confidence score rules and updates question', () async {
      final mapping = await mappingService.createMapping(
        questionId: 'Q_MAP_1',
        conceptId: 'C_PREAMBLE_OBJECTIVES',
        confidenceScore: 0.95, // Exact Match
        mappingMethod: MappingMethod.manual,
      );

      expect(mapping.reviewStatus, equals(ReviewStatus.pending));
      expect(mapping.confidenceCategory, equals(ConfidenceCategory.exactMatch));

      final updatedQ = await pyqRepo.getQuestionById('Q_MAP_1');
      expect(updatedQ!.conceptsTested, contains('C_PREAMBLE_OBJECTIVES'));
    });

    test('createMapping auto-rejects mappings below 0.50 score', () async {
      final mapping = await mappingService.createMapping(
        questionId: 'Q_MAP_1',
        conceptId: 'C_LOW_CONFIDENCE',
        confidenceScore: 0.35, // Rejected threshold (< 0.50)
        mappingMethod: MappingMethod.ruleBased,
      );

      expect(mapping.reviewStatus, equals(ReviewStatus.rejected));
      expect(mapping.isAutoRejected, isTrue);

      final q = await pyqRepo.getQuestionById('Q_MAP_1');
      expect(q!.conceptsTested.contains('C_LOW_CONFIDENCE'), isFalse);
    });

    test('reviewMapping approves mapping and updates reviewer details', () async {
      await mappingService.createMapping(
        questionId: 'Q_MAP_1',
        conceptId: 'C_PREAMBLE_OBJECTIVES',
        confidenceScore: 0.80,
        mappingMethod: MappingMethod.knowledgeGraphAssisted,
      );

      final reviewed = await mappingService.reviewMapping(
        questionId: 'Q_MAP_1',
        conceptId: 'C_PREAMBLE_OBJECTIVES',
        newStatus: ReviewStatus.approved,
        reviewerId: 'REV_101',
        remarks: 'Verified against official syllabus',
      );

      expect(reviewed!.reviewStatus, equals(ReviewStatus.approved));
      expect(reviewed.reviewedBy, equals('REV_101'));
    });
  });
}
