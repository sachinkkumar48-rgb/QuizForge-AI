import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportValidator Phase-2 checks', () {
    test('rejects placeholder content in title and summary', () {
      final report = ReportSeedCorpus.phase1Reports.first.copyWith(
        id: 'rep_placeholder',
        officialTitle: 'Report TBD for review',
        executiveSummary: 'Lorem ipsum placeholder text',
      );

      final result = ReportValidator.validate(report);

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.field == 'officialTitle'), isTrue);
      expect(result.issues.any((i) => i.field == 'executiveSummary'), isTrue);
    });

    test('rejects malformed publication date', () {
      final report = ReportSeedCorpus.phase1Reports.first.copyWith(
        id: 'rep_bad_date',
        publicationDate: '31/12/2024',
      );

      final result = ReportValidator.validate(report);

      expect(result.issues.any((i) => i.field == 'publicationDate'), isTrue);
    });

    test('rejects implausible publication year', () {
      final report = ReportSeedCorpus.phase1Reports.first.copyWith(
        id: 'rep_bad_year',
        publicationYear: 1450,
      );

      final result = ReportValidator.validate(report);

      expect(result.issues.any((i) => i.field == 'publicationYear'), isTrue);
    });

    test('rejects reporting period later than publication year', () {
      final report = ReportSeedCorpus.phase1Reports.first.copyWith(
        id: 'rep_bad_period',
        reportingPeriod: '2026-27',
        publicationYear: 2024,
      );

      final result = ReportValidator.validate(report);

      expect(result.issues.any((i) => i.field == 'reportingPeriod'), isTrue);
    });

    test('flags broken cross-package references when known sets are supplied',
        () {
      final report = ReportSeedCorpus.phase1Reports.first.copyWith(
        id: 'rep_broken_cross',
        relatedArticleIds: const ['Article 999'],
        relatedCommitteeIds: const ['comm_missing'],
        relatedBodies: const ['bod_missing'],
      );

      final result = ReportValidator.validate(
        report,
        knownArticleIds: const {'Article 112', 'Article 21'},
        knownCommitteeIds: const {'comm_fc_15th_2017'},
        knownBodyIds: const {'bod_rbi', 'bod_sebi'},
      );

      expect(result.issues.any((i) => i.field == 'relatedArticleIds'), isTrue);
      expect(result.issues.any((i) => i.field == 'relatedCommitteeIds'), isTrue);
      expect(result.issues.any((i) => i.field == 'relatedBodies'), isTrue);
    });

    test('passes valid cross-package references', () {
      final report = ReportSeedCorpus.phase1Reports.first;

      final result = ReportValidator.validate(
        report,
        knownArticleIds: const {'Article 112', 'Article 265'},
        knownCommitteeIds: const {'comm_fc_15th_2017', 'comm_fc_16th_2026'},
        knownSchemeNames: const {'POSHAN Abhiyaan'},
      );

      expect(result.issues.any((i) => i.field == 'relatedArticleIds'), isFalse);
      expect(
          result.issues.any((i) => i.field == 'relatedCommitteeIds'), isFalse);
      expect(
          result.issues.any((i) => i.field == 'relatedSchemeNames'), isFalse);
    });
  });

  group('ReportValidator Index & Survey & Indicator checks', () {
    test('validates a valid Index Knowledge Object', () {
      final index = ReportSeedCorpus.phase1Indices.first;
      final result = ReportValidator.validateIndex(index);
      expect(result.isValid, isTrue);
    });

    test('detects invalid Index with missing publisher and evidence', () {
      final invalid = IndexKnowledgeObject(
        id: 'idx_invalid',
        indexName: 'Invalid Index',
        publisher: '',
        latestEditionYear: 0,
      );
      final result = ReportValidator.validateIndex(invalid);
      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.field == 'publisher'), isTrue);
      expect(result.issues.any((i) => i.field == 'latestEditionYear'), isTrue);
      expect(result.issues.any((i) => i.field == 'officialUrl'), isTrue);
      expect(result.issues.any((i) => i.field == 'evidenceIds'), isTrue);
    });

    test('detects duplicate Index by name', () {
      final index = ReportSeedCorpus.phase1Indices.first;
      final duplicate = index.copyWith(id: 'idx_dup', indexName: index.indexName);
      final result =
          ReportValidator.validateIndex(duplicate, existingIndices: [index]);
      expect(result.issues.any((i) => i.field == 'duplicate'), isTrue);
    });

    test('validates a valid Survey Knowledge Object', () {
      final survey = ReportSeedCorpus.phase1Surveys.first;
      final result = ReportValidator.validateSurvey(survey);
      expect(result.isValid, isTrue);
    });

    test('detects invalid Survey with missing title and year', () {
      final invalid = SurveyKnowledgeObject(
        id: 'srv_invalid',
        officialTitle: '',
        publishingOrganisation: '',
        surveyYear: 0,
      );
      final result = ReportValidator.validateSurvey(invalid);
      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.field == 'officialTitle'), isTrue);
      expect(result.issues.any((i) => i.field == 'surveyYear'), isTrue);
    });

    test('detects malformed indicator value', () {
      final invalid = ReportSeedCorpus.phase1Indicators.first.copyWith(
        id: 'ind_invalid_value',
        value: 'approx',
      );
      final result = ReportValidator.validateIndicator(invalid);
      expect(result.issues.any((i) => i.field == 'value'), isTrue);
    });
  });
}
