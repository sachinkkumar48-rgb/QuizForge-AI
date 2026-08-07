import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsAnalytics & Trend Engine Tests', () {
    late List<CurrentAffairsKnowledgeObject> mockObjects;

    setUp(() {
      final e1 = NewsEvent(
        id: 'analytics_1',
        headline: 'Article 21 Judicial Interpretation',
        summary: 'Puttaswamy case discussed in basic structure context.',
        content: 'Judicial review on Digital Personal Data Protection Act, 2023.',
        officialSource: 'Supreme Court of India',
        publicationDate: DateTime(2026, 1, 10),
        category: CurrentAffairsCategory.polity,
        keywords: ['Judiciary', 'Privacy', 'Rights'],
      );

      final e2 = NewsEvent(
        id: 'analytics_2',
        headline: 'Constitutional amendment on Federalism',
        summary: 'Article 368 and 7th Schedule debate in Parliament.',
        content: 'Minerva Mills judgment cited.',
        officialSource: 'Parliament',
        publicationDate: DateTime(2026, 1, 20),
        category: CurrentAffairsCategory.polity,
        keywords: ['Parliament', 'Federalism', 'Privacy'],
      );

      final e3 = NewsEvent(
        id: 'analytics_3',
        headline: 'RBI monetary stance on inflation',
        summary: 'Repo rate update.',
        content: 'Economic growth projections.',
        officialSource: 'RBI',
        publicationDate: DateTime(2026, 2, 5),
        category: CurrentAffairsCategory.economy,
        keywords: ['Banking', 'Inflation'],
      );

      mockObjects = [
        CurrentAffairsMapper.mapToKnowledgeObject(e1),
        CurrentAffairsMapper.mapToKnowledgeObject(e2),
        CurrentAffairsMapper.mapToKnowledgeObject(e3),
      ];
    });

    test('should generate accurate analytics report', () {
      final report = CurrentAffairsAnalytics.generateReport(mockObjects);

      expect(report.totalEventsCount, equals(3));
      expect(report.categoryCounts[CurrentAffairsCategory.polity], equals(2));
      expect(report.categoryCounts[CurrentAffairsCategory.economy], equals(1));
      expect(report.topLinkedArticles.containsKey('Article 21'), isTrue);
      expect(report.topLinkedCases.containsKey('K.S. Puttaswamy v. Union of India (2017)'), isTrue);
      expect(report.heatmapByMonth['2026-01'], equals(2));
      expect(report.heatmapByMonth['2026-02'], equals(1));
      expect(report.averageRelevanceScore, greaterThan(0));
    });

    test('should generate trend analysis identifying top categories and emerging keywords', () {
      final trend = CurrentAffairsTrendEngine.analyzeTrends(mockObjects);

      expect(trend.topCategory, equals(CurrentAffairsCategory.polity));
      expect(trend.topCategoryPercentage, closeTo(66.7, 0.5));
      expect(trend.emergingKeywords, contains('privacy'));
      expect(trend.weightDistribution[CurrentAffairsCategory.polity], closeTo(66.7, 0.5));
    });

    test('should return empty report and trend when object list is empty', () {
      final emptyReport = CurrentAffairsAnalytics.generateReport([]);
      expect(emptyReport.totalEventsCount, equals(0));
      expect(emptyReport.averageRelevanceScore, equals(0.0));

      final emptyTrend = CurrentAffairsTrendEngine.analyzeTrends([]);
      expect(emptyTrend.topCategoryPercentage, equals(0.0));
      expect(emptyTrend.emergingKeywords, isEmpty);
    });
  });
}
