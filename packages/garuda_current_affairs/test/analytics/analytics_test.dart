import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsAnalytics & CurrentAffairsTrendEngine Tests', () {
    test('Calculates analytics metrics and top linked articles/acts', () {
      final e1 = NewsEvent(
        id: 'a1',
        headline: 'Article 14 ruling by Supreme Court',
        summary: 'Judgement on Article 14 and Basic Structure.',
        content: 'Article 14 and Basic Structure doctrine discussed.',
        officialSource: 'Supreme Court',
        publicationDate: DateTime(2025, 6, 1),
        category: CurrentAffairsCategory.polity,
        keywords: ['constitutional law', 'judiciary'],
      );

      final ko1 = CurrentAffairsMapper.mapToKnowledgeObject(e1);
      final report = CurrentAffairsAnalytics.generateReport([ko1]);

      expect(report.totalEventsCount, equals(1));
      expect(report.categoryCounts[CurrentAffairsCategory.polity], equals(1));
      expect(report.topLinkedArticles.containsKey('Article 14'), isTrue);

      final trend = CurrentAffairsTrendEngine.analyzeTrends([ko1]);
      expect(trend.topCategory, equals(CurrentAffairsCategory.polity));
      expect(trend.emergingKeywords.contains('constitutional law'), isTrue);
    });
  });
}
