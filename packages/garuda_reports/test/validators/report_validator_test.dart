import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportValidator Tests', () {
    test('should validate a valid Report Knowledge Object', () {
      final report = ReportSeedCorpus.phase1Reports.first;

      final result = ReportValidator.validate(report);

      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('should detect missing metadata, official URL and evidence', () {
      final invalid = ReportKnowledgeObject(
        id: 'rep_invalid',
        officialTitle: '',
        shortName: 'Invalid',
        category: ReportCategory.economy,
        publishingOrganisation: '',
        publicationYear: 0,
      );

      final result = ReportValidator.validate(invalid);

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.field == 'officialTitle'), isTrue);
      expect(result.issues.any((i) => i.field == 'publishingOrganisation'),
          isTrue);
      expect(result.issues.any((i) => i.field == 'publicationYear'), isTrue);
      expect(result.issues.any((i) => i.field == 'officialUrl'), isTrue);
      expect(result.issues.any((i) => i.field == 'evidenceIds'), isTrue);
    });

    test('should detect duplicate report with matching title and year', () {
      final report1 = ReportSeedCorpus.phase1Reports.first;
      final duplicate = report1.copyWith(id: 'rep_duplicate_id');

      final result =
          ReportValidator.validate(duplicate, existingReports: [report1]);

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.field == 'duplicate'), isTrue);
    });

    test('should detect broken reference to a missing index', () {
      final report = ReportSeedCorpus.phase1Reports.first.copyWith(
        id: 'rep_broken_ref',
        relatedIndexIds: const ['idx_does_not_exist'],
      );

      final result = ReportValidator.validate(
        report,
        knownIndices: ReportSeedCorpus.phase1Indices,
      );

      expect(result.issues.any((i) => i.field == 'relatedIndexIds'), isTrue);
    });

    test('should detect invalid relationship with non-existent source', () {
      final report = ReportSeedCorpus.phase1Reports.first.copyWith(
        id: 'rep_rel_check',
        relationships: const [
          ReportRelationship(
            sourceId: 'ghost_report',
            targetId: 'rep_es_2024_25',
            relationshipType: RelationshipType.citesReport,
          ),
        ],
      );

      final result = ReportValidator.validate(
        report,
        existingReports: ReportSeedCorpus.phase1Reports,
        knownIndices: ReportSeedCorpus.phase1Indices,
        knownSurveys: ReportSeedCorpus.phase1Surveys,
      );

      expect(result.issues.any((i) => i.field == 'relationships'), isTrue);
    });
  });
}
