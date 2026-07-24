import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

import '../../domain/services/recommendation_service_test.dart';

void main() {
  group('PYQIngestionService Tests', () {
    late FakeKnowledgeRepository repository;
    late PYQIngestionService ingestionService;

    final validQ1 = PreviousYearQuestion(
      id: 'pyq-401',
      question:
          'With reference to Indian Judiciary, consider the following statements...',
      options: ['1 only', '2 only', 'Both 1 and 2', 'Neither 1 nor 2'],
      answer: '1 only',
      explanation:
          'Supreme Court has power of judicial review under Article 137.',
      exam: 'UPSC CSE',
      year: 2023,
      paper: 'GS Paper I',
      subject: 'Polity',
      topics: ['Judiciary', 'Supreme Court'],
    );

    final validQ2 = PreviousYearQuestion(
      id: 'pyq-402',
      question:
          'Consider the following heavy industries: 1. Fertilizer 2. Steel 3. Cement...',
      options: ['1 and 2', '2 and 3', '1, 2 and 3', '3 only'],
      answer: '1, 2 and 3',
      explanation: 'All three are classified under core industries.',
      exam: 'UPSC CSE',
      year: 2022,
      paper: 'GS Paper I',
      subject: 'Economy',
      topics: ['Industries', 'Core Sectors'],
    );

    setUp(() {
      repository = FakeKnowledgeRepository();
      ingestionService = PYQIngestionService(repository: repository);
    });

    test('validate delegates to PYQParser', () {
      final validation = ingestionService.validate(validQ1);
      expect(validation.isValid, isTrue);
    });

    test('mapToKnowledge converts PYQ to KnowledgeObject', () {
      final kObj = ingestionService.mapToKnowledge(validQ1);
      expect(kObj.id, equals('pyq-401'));
      expect(kObj.type, equals(KnowledgeType.pyq));
    });

    test('ingest batch stores mapped KnowledgeObjects in repository', () async {
      final result = await ingestionService.ingestBatch([validQ1, validQ2]);

      expect(result.isValid, isTrue);
      expect(result.statistics['processedCount'], equals(2));
      expect(result.statistics['skippedCount'], equals(0));

      final stored1 = await repository.findById('pyq-401');
      expect(stored1, isNotNull);
      expect(stored1!.type, equals(KnowledgeType.pyq));
      expect(stored1.metadata['exam'], equals('UPSC CSE'));
    });

    test('ingest single question shortcut works', () async {
      final result = await ingestionService.ingest(validQ1);

      expect(result.isValid, isTrue);
      expect(result.statistics['processedCount'], equals(1));

      final stored = await repository.findById('pyq-401');
      expect(stored, isNotNull);
    });

    test('ingestBatch tracks skipped invalid questions when validation fails',
        () async {
      final invalidQ = PreviousYearQuestion(
        id: '',
        question: '   ',
        options: [],
        answer: '',
      );

      final result = await ingestionService.ingestBatch([validQ1, invalidQ]);

      expect(result.isValid, isFalse);
      expect(result.statistics['processedCount'], equals(1));
      expect(result.statistics['skippedCount'], equals(1));
      expect(result.errors, isNotEmpty);
    });
  });
}
