import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_committees/garuda_committees.dart';

void main() {
  group('CommitteeAnalyticsEngine Tests', () {
    late List<CommitteeKnowledgeObject> mockCommittees;

    setUp(() {
      mockCommittees = CommitteeSeedCorpus.phase1Committees;
    });

    test('should generate accurate analytics report over seed corpus', () {
      final report = CommitteeAnalyticsEngine.generateReport(mockCommittees);

      expect(report.totalCommittees, equals(mockCommittees.length));
      expect(report.categoryDistribution.containsKey(CommitteeCategory.executive), isTrue);
      expect(report.averageRecommendationsPerCommittee, greaterThan(0));
      expect(report.topLinkedArticles.containsKey('Article 263'), isTrue);
    });

    test('should handle empty committee list gracefully', () {
      final report = CommitteeAnalyticsEngine.generateReport([]);

      expect(report.totalCommittees, equals(0));
      expect(report.averageRecommendationsPerCommittee, equals(0.0));
      expect(report.pyqMappingDensity, equals(0.0));
    });
  });
}
