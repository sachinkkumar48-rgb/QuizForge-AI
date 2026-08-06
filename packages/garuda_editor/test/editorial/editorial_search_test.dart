import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('EditorialSearchEngine Tests', () {
    late List<KnowledgeObject> sampleObjects;

    setUp(() {
      sampleObjects = [
        KnowledgeObject(
          id: 'ko_polity_01',
          title: 'Article 21 Right to Life',
          content: 'No person shall be deprived of his life or personal liberty.',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          officialSource: 'Constitution',
          evidenceIds: const ['ev_1'],
          status: EditorialStatus.published,
          package: 'garuda_constitution',
          knowledgeType: 'Article',
        ),
        KnowledgeObject(
          id: 'ko_hist_01',
          title: 'Non-Cooperation Movement 1920',
          content: 'Mahatma Gandhi launched the Non-Cooperation Movement.',
          subject: 'History',
          topic: 'Freedom Struggle',
          officialSource: 'NCERT Official',
          evidenceIds: const ['ev_2'],
          status: EditorialStatus.pendingReview,
          package: 'garuda_knowledge',
          knowledgeType: 'HistoricalEvent',
        ),
      ];
    });

    test('EditorialSearchEngine filters by status, package, and keyword', () {
      final resStatus = EditorialSearchEngine.search(
        objects: sampleObjects,
        query: const EditorialSearchQuery(status: EditorialStatus.published),
      );
      expect(resStatus.length, equals(1));
      expect(resStatus.first.id, equals('ko_polity_01'));

      final resKw = EditorialSearchEngine.search(
        objects: sampleObjects,
        query: const EditorialSearchQuery(keyword: 'Gandhi'),
      );
      expect(resKw.length, equals(1));
      expect(resKw.first.id, equals('ko_hist_01'));

      final resPkg = EditorialSearchEngine.search(
        objects: sampleObjects,
        query: const EditorialSearchQuery(package: 'garuda_constitution'),
      );
      expect(resPkg.length, equals(1));
      expect(resPkg.first.id, equals('ko_polity_01'));
    });
  });
}
