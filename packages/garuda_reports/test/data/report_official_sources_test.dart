import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportOfficialSources evidence registry', () {
    test('resolves every seed corpus record to an official URL', () {
      final ids = <String>[
        for (final r in ReportSeedCorpus.phase1Reports) r.id,
        for (final i in ReportSeedCorpus.phase1Indices) i.id,
        for (final s in ReportSeedCorpus.phase1Surveys) s.id,
        for (final i in ReportSeedCorpus.phase1Indicators) i.id,
      ];
      expect(ids, isNotEmpty);
      for (final id in ids) {
        expect(ReportOfficialSources.sourceUrlFor(id), isNotEmpty,
            reason: 'missing official source for $id');
      }
    });

    test('resolves every corpus evidence ID to an official URL', () {
      final evidenceIds = <String>{};
      for (final r in ReportSeedCorpus.phase1Reports) {
        evidenceIds.addAll(r.evidenceIds);
      }
      for (final i in ReportSeedCorpus.phase1Indices) {
        evidenceIds.addAll(i.evidenceIds);
      }
      for (final s in ReportSeedCorpus.phase1Surveys) {
        evidenceIds.addAll(s.evidenceIds);
      }
      for (final i in ReportSeedCorpus.phase1Indicators) {
        evidenceIds.addAll(i.evidenceIds);
      }
      expect(evidenceIds, isNotEmpty);
      for (final id in evidenceIds) {
        expect(ReportOfficialSources.evidenceUrlFor(id), isNotEmpty,
            reason: 'unresolvable evidence reference $id');
      }
    });

    test('evidence coverage over the seeded corpus is complete', () {
      final all = <dynamic>[
        ...ReportSeedCorpus.phase1Reports,
        ...ReportSeedCorpus.phase1Indices,
        ...ReportSeedCorpus.phase1Surveys,
        ...ReportSeedCorpus.phase1Indicators,
      ];
      expect(ReportCorpusSupport.evidenceCoverage(all), greaterThan(0.99));
      expect(ReportSeedCorpus.corpusEvidenceCoverage, greaterThan(0.99));
    });

    test('unknown evidence ID resolves empty', () {
      expect(ReportOfficialSources.evidenceUrlFor('ev_nonexistent'), isEmpty);
    });
  });

  group('ReportCorpusSupport enrichment', () {
    test('applies lastVerifiedDate and evidenceVerified status to a record',
        () {
      final enriched = ReportCorpusSupport.enrichReport(
        ReportSeedCorpus.phase1Reports.first.copyWith(
          lastVerifiedDate: '',
          editorialStatus: EditorialStatus.imported,
        ),
      );
      expect(enriched.lastVerifiedDate, isNotEmpty);
      expect(enriched.editorialStatus, EditorialStatus.evidenceVerified);
    });

    test('keeps an already-published record untouched by status promotion',
        () {
      final published = ReportCorpusSupport.enrichReport(
        ReportSeedCorpus.phase1Reports.first.copyWith(
          editorialStatus: EditorialStatus.published,
        ),
      );
      expect(published.editorialStatus, EditorialStatus.published);
    });
  });
}
