import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

import '../../domain/services/recommendation_service_test.dart';

void main() {
  group('CurrentAffairsIngestionService Tests', () {
    late FakeKnowledgeRepository repository;
    late CurrentAffairsIngestionService ingestionService;

    final pubDate = DateTime.parse('2026-07-21T12:00:00.000Z');

    final validItem1 = CurrentAffairsItem(
      id: 'ca-201',
      title: 'Digital Public Infrastructure Governance',
      summary: 'DPI framework for citizen service delivery.',
      source: 'PIB Press Bureau',
      publicationDate: pubDate,
      content:
          'India Digital Public Infrastructure framework enhances citizen service delivery.',
      category: 'Governance',
      tags: ['Governance', 'Technology'],
      relatedSubjects: ['GS Paper II'],
    );

    final validItem2 = CurrentAffairsItem(
      id: 'ca-202',
      title: 'RAMSAR Wetland Site Additions',
      summary: 'Three new wetland sites added to RAMSAR list.',
      source: 'Ministry of Environment',
      publicationDate: pubDate,
      content:
          'Three new wetland sites added to the RAMSAR list, raising total count to 85.',
      category: 'Environment',
      tags: ['Environment', 'Ecology'],
      relatedSubjects: ['GS Paper III'],
    );

    setUp(() {
      repository = FakeKnowledgeRepository();
      ingestionService = CurrentAffairsIngestionService(
        repository: repository,
      );
    });

    test('validate delegates to CurrentAffairsParser', () {
      final validation = ingestionService.validate(validItem1);
      expect(validation.isValid, isTrue);
    });

    test('mapToKnowledge maps item to KnowledgeObject', () {
      final kObj = ingestionService.mapToKnowledge(validItem1);
      expect(kObj.id, equals('ca-201'));
      expect(kObj.type, equals(KnowledgeType.article));
      expect(kObj.title, equals('Digital Public Infrastructure Governance'));
    });

    test(
        'ingest batch converts valid items into stored KnowledgeObjects in repository',
        () async {
      final result =
          await ingestionService.ingestBatch([validItem1, validItem2]);

      expect(result.isValid, isTrue);
      expect(result.statistics['processedCount'], equals(2));
      expect(result.statistics['skippedCount'], equals(0));
      expect(result.statistics['savedKnowledgeObjectsCount'], equals(2));

      final storedObj1 = await repository.findById('ca-201');
      expect(storedObj1, isNotNull);
      expect(storedObj1!.type, equals(KnowledgeType.article));
      expect(
          storedObj1.title, equals('Digital Public Infrastructure Governance'));
      expect(storedObj1.metadata['itemId'], equals('ca-201'));
      expect(storedObj1.metadata['source'], equals('PIB Press Bureau'));
      expect(storedObj1.metadata['contentType'], equals('current_affairs'));

      final storedObj2 = await repository.findById('ca-202');
      expect(storedObj2, isNotNull);
      expect(storedObj2!.categoryOrTag, isNotNull);
    });

    test('ingest single item convenience method works', () async {
      final result = await ingestionService.ingest(validItem1);

      expect(result.isValid, isTrue);
      expect(result.statistics['processedCount'], equals(1));

      final storedObj = await repository.findById('ca-201');
      expect(storedObj, isNotNull);
    });

    test('ingestBatch tracks skipped invalid items when validation fails',
        () async {
      final invalidItem = CurrentAffairsItem(
        id: '',
        title: '   ',
        content: '',
      );

      final result =
          await ingestionService.ingestBatch([validItem1, invalidItem]);

      expect(result.isValid, isFalse);
      expect(result.statistics['processedCount'], equals(1));
      expect(result.statistics['skippedCount'], equals(1));
      expect(result.errors, isNotEmpty);
    });
  });
}

extension on KnowledgeObject {
  String get categoryOrTag => metadata['category'] as String? ?? 'General';
}
