import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('ConceptSearchService Tests', () {
    late OfflinePYQRepository pyqRepo;
    late OfflineConceptRepository conceptRepo;
    late OfflineQuestionConceptRepository mappingRepo;
    late ConceptSearchService searchService;

    setUp(() async {
      pyqRepo = OfflinePYQRepository();
      conceptRepo = OfflineConceptRepository();
      mappingRepo = OfflineQuestionConceptRepository();
      searchService = ConceptSearchService(
        pyqRepository: pyqRepo,
        conceptRepository: conceptRepo,
        mappingRepository: mappingRepo,
      );

      final now = DateTime.now();

      final concept = Concept(
        id: 'C_DPSP',
        name: 'Directive Principles of State Policy',
        aliases: const ['Part IV', 'Socialistic Principles'],
        description: 'Non-justiciable guidelines for state governance.',
        subject: 'Polity',
        module: 'Constitutional Framework',
        topic: 'DPSP',
        knowledgeObjectIds: const ['KO_DPSP_ART_39'],
        createdAt: now,
        updatedAt: now,
      );

      await conceptRepo.saveConcept(concept);

      final q = Question(
        id: 'Q_DPSP_1',
        examId: 'upsc_cse',
        year: 2023,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'DPSP',
        originalQuestion: 'Which Article promotes equal justice and free legal aid?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Article 39A inserted by 42nd Amendment.',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: now,
          checksum: '111',
        ),
        articleLinks: const ['Article 39A'],
        knowledgeObjectLinks: const ['KO_DPSP_ART_39'],
      );

      await pyqRepo.saveQuestion(q);
    });

    test('search by keyword across concept and questions', () async {
      final result = await searchService.search(keyword: 'Directive');
      expect(result.concepts.length, equals(1));
      expect(result.concepts.first.id, equals('C_DPSP'));
    });

    test('search by Article link finds relevant questions', () async {
      final result = await searchService.search(article: 'Article 39A');
      expect(result.questions.length, equals(1));
      expect(result.questions.first.id, equals('Q_DPSP_1'));
    });

    test('search by Knowledge Object ID returns matched knowledge object list', () async {
      final result = await searchService.search(knowledgeObjectId: 'KO_DPSP_ART_39');
      expect(result.concepts.length, equals(1));
      expect(result.matchingKnowledgeObjectIds, contains('KO_DPSP_ART_39'));
    });
  });
}
