import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('CurrentAffairsMapper Tests', () {
    final mapper = CurrentAffairsMapper();
    final pubDate = DateTime.parse('2026-07-23T12:00:00.000Z');

    test(
        'mapToKnowledge transforms CurrentAffairsItem into canonical KnowledgeObject',
        () {
      final item = CurrentAffairsItem(
        id: 'ca-200',
        title: 'Digital Public Infrastructure Framework',
        summary: 'Overview of India DPI framework.',
        content:
            'Detailed discussion on Digital Public Infrastructure and citizen governance.',
        publicationDate: pubDate,
        source: 'PIB Bureau',
        category: 'Governance',
        tags: ['Governance', 'Digital India'],
        relatedSubjects: ['GS Paper II'],
      );

      final kObj = mapper.mapToKnowledge(item);

      expect(kObj.id, equals('ca-200'));
      expect(kObj.type, equals(KnowledgeType.article));
      expect(kObj.title, equals('Digital Public Infrastructure Framework'));
      expect(kObj.summary, equals('Overview of India DPI framework.'));
      expect(kObj.source, equals('PIB Bureau'));
      expect(kObj.subjects, equals(['GS Paper II']));
      expect(kObj.topics, containsAll(['Governance', 'Digital India']));
      expect(kObj.keywords,
          containsAll(['Governance', 'Digital India', 'GS Paper II']));
      expect(kObj.metadata['itemId'], equals('ca-200'));
      expect(kObj.metadata['category'], equals('Governance'));
      expect(kObj.metadata['contentType'], equals('current_affairs'));
    });

    test('mapToKnowledge generates summary fallback when item summary is empty',
        () {
      final item = CurrentAffairsItem(
        id: 'ca-201',
        title: 'Short Article Title',
        summary: '',
        content: 'This is a short body content for testing summary generation.',
        source: 'Press Bureau',
      );

      final kObj = mapper.mapToKnowledge(item);

      expect(
          kObj.summary,
          equals(
              'This is a short body content for testing summary generation.'));
    });
  });
}
