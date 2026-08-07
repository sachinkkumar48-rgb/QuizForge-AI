import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsDigestEngine Tests', () {
    test('Generates structured markdown digest brief for monthly compilation', () {
      final e1 = NewsEvent(
        id: 'd1',
        headline: 'G20 Summit Declaration on Global Biofuel Alliance',
        summary: 'Leaders adopt declaration endorsing Global Biofuel Alliance.',
        content: 'Full details of G20 declaration and renewable energy goals.',
        officialSource: 'PIB',
        publicationDate: DateTime(2025, 9, 10),
        category: CurrentAffairsCategory.internationalRelations,
        importance: CurrentAffairsImportance.high,
      );

      final ko1 = CurrentAffairsMapper.mapToKnowledgeObject(e1);

      final digest = CurrentAffairsDigestEngine.generateDigest(
        objects: [ko1],
        frequency: DigestFrequency.monthly,
      );

      expect(digest.title, contains('MONTHLY'));
      expect(digest.markdownContent, contains('G20 Summit Declaration'));
      expect(digest.items.length, equals(1));
    });
  });
}
