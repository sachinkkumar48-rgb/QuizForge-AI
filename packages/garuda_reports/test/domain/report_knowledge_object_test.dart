import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportKnowledgeObject Serialization & Domain Tests', () {
    test('should round-trip Report Knowledge Object through JSON', () {
      final original = ReportSeedCorpus.phase1Reports.first;

      final restored = ReportKnowledgeObject.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.officialTitle, equals(original.officialTitle));
      expect(restored.category, equals(original.category));
      expect(restored.publicationYear, equals(original.publicationYear));
      expect(restored.publishingOrganisation,
          equals(original.publishingOrganisation));
      expect(restored.relatedArticleIds, equals(original.relatedArticleIds));
      expect(restored.relatedPyqIds, equals(original.relatedPyqIds));
      expect(restored.lastVerifiedDate, equals(original.lastVerifiedDate));
    });

    test('lastVerifiedDate survives JSON round-trip across all entity types',
        () {
      final report = ReportSeedCorpus.phase1Reports.first;
      final index = ReportSeedCorpus.phase1Indices.first;
      final survey = ReportSeedCorpus.phase1Surveys.first;
      final indicator = ReportSeedCorpus.phase1Indicators.first;

      expect(report.lastVerifiedDate, isNotEmpty);
      expect(
        ReportKnowledgeObject.fromJson(report.toJson()).lastVerifiedDate,
        equals(report.lastVerifiedDate),
      );
      expect(
        IndexKnowledgeObject.fromJson(index.toJson()).lastVerifiedDate,
        equals(index.lastVerifiedDate),
      );
      expect(
        SurveyKnowledgeObject.fromJson(survey.toJson()).lastVerifiedDate,
        equals(survey.lastVerifiedDate),
      );
      expect(
        IndicatorKnowledgeObject.fromJson(indicator.toJson()).lastVerifiedDate,
        equals(indicator.lastVerifiedDate),
      );
    });

    test('should preserve embedded chapters, statistics and recommendations',
        () {
      final es = ReportSeedCorpus.phase1Reports
          .firstWhere((r) => r.id == 'rep_es_2024_25');
      final restored = ReportKnowledgeObject.fromJson(es.toJson());

      expect(restored.chapters, hasLength(1));
      expect(restored.importantStatistics, isNotEmpty);
      expect(restored.recommendations, hasLength(2));
      expect(restored.recommendations.first.reportId, equals('rep_es_2024_25'));
    });

    test('copyWith should update fields immutably', () {
      final original = ReportSeedCorpus.phase1Reports.first;
      final updated = original.copyWith(shortName: 'ES 2025');

      expect(original.shortName, isNot(equals('ES 2025')));
      expect(updated.shortName, equals('ES 2025'));
      expect(updated.id, equals(original.id));
    });

    test('should bridge to GARUDA Editorial KnowledgeObject', () {
      final es = ReportSeedCorpus.phase1Reports
          .firstWhere((r) => r.id == 'rep_es_2024_25');
      final ko = es.toGarudaKnowledgeObject();

      expect(ko.package, equals('garuda_reports'));
      expect(ko.knowledgeType, equals('ReportKnowledgeObject'));
      expect(ko.evidenceIds, isNotEmpty);
      expect(ko.metadata['officialSource'], isNotEmpty);
    });
  });

  group('IndexKnowledgeObject Serialization Tests', () {
    test('should round-trip Index Knowledge Object through JSON', () {
      final original = ReportSeedCorpus.phase1Indices.first;

      final restored = IndexKnowledgeObject.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.indexName, equals(original.indexName));
      expect(restored.publisher, equals(original.publisher));
      expect(restored.trend, equals(original.trend));
      expect(restored.indicators, equals(original.indicators));
    });

    test('should preserve edition history', () {
      final ghi = ReportSeedCorpus.phase1Indices
          .firstWhere((i) => i.id == 'idx_ghi_2024');
      final restored = IndexKnowledgeObject.fromJson(ghi.toJson());

      expect(restored.editionHistory, hasLength(2));
      expect(restored.indiasRanking, contains('105'));
    });

    test('should bridge index to GARUDA Editorial KnowledgeObject', () {
      final ghi = ReportSeedCorpus.phase1Indices
          .firstWhere((i) => i.id == 'idx_ghi_2024');
      final ko = ghi.toGarudaKnowledgeObject();

      expect(ko.knowledgeType, equals('IndexKnowledgeObject'));
      expect(ko.metadata['indiasRanking'], equals(ghi.indiasRanking));
    });
  });

  group('SurveyKnowledgeObject Serialization Tests', () {
    test('should round-trip Survey Knowledge Object through JSON', () {
      final original = ReportSeedCorpus.phase1Surveys.first;

      final restored = SurveyKnowledgeObject.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.officialTitle, equals(original.officialTitle));
      expect(restored.importantStatistics, isNotEmpty);
      expect(restored.keyFindings, isNotEmpty);
    });
  });

  group('IndicatorKnowledgeObject Serialization Tests', () {
    test('should round-trip Indicator Knowledge Object through JSON', () {
      final original = ReportSeedCorpus.phase1Indicators.first;

      final restored = IndicatorKnowledgeObject.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.value, equals(original.value));
      expect(restored.relatedPyqIds, isNotEmpty);
    });
  });

  group('RecommendationKnowledgeObject Serialization Tests', () {
    test('should round-trip Recommendation through JSON', () {
      final es = ReportSeedCorpus.phase1Reports
          .firstWhere((r) => r.id == 'rep_es_2024_25');
      final original = es.recommendations.first;

      final restored =
          RecommendationKnowledgeObject.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.status, equals(original.status));
      expect(restored.reportId, equals('rep_es_2024_25'));
    });
  });
}
