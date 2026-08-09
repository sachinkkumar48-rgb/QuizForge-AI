import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P10 — Chronological analysis behavior (TITAN-KO-015.0 P10).
///
/// Ordering must be deterministic and use only the authoritative existing dates
/// (judgment year, then judgment date). Chronology is a structural fact and
/// never a legal conclusion.
void main() {
  final service = CrossCaseAnalysisService();

  group('A. chronological ordering', () {
    test('orders by authoritative judgment year', () {
      final analysis = service.chronologicalAnalysis(
          ['MINERVA_MILLS', 'GOLAKNATH', 'KESAVANANDA', 'SAJJAN_SINGH']);
      expect(analysis.caseIds,
          ['SAJJAN_SINGH', 'GOLAKNATH', 'KESAVANANDA', 'MINERVA_MILLS']);
      expect(analysis.entries.map((e) => e.year), [1965, 1967, 1973, 1980]);
      expect(analysis.entries.map((e) => e.position), [0, 1, 2, 3]);
    });

    test('exposes earliest, latest and year span', () {
      final analysis = service.chronologicalAnalysis(
          ['MINERVA_MILLS', 'GOLAKNATH', 'KESAVANANDA', 'SAJJAN_SINGH']);
      expect(analysis.earliest!.caseId, 'SAJJAN_SINGH');
      expect(analysis.latest!.caseId, 'MINERVA_MILLS');
      expect(analysis.yearSpan, 15);
    });

    test('positionOf, before and after are consistent', () {
      final analysis = service.chronologicalAnalysis(
          ['MINERVA_MILLS', 'GOLAKNATH', 'KESAVANANDA', 'SAJJAN_SINGH']);
      expect(analysis.positionOf('KESAVANANDA'), 2);
      expect(analysis.before('KESAVANANDA').map((e) => e.caseId),
          ['SAJJAN_SINGH', 'GOLAKNATH']);
      expect(analysis.after('KESAVANANDA').map((e) => e.caseId),
          ['MINERVA_MILLS']);
      expect(analysis.positionOf('NO_SUCH_CASE'), isNull);
      expect(analysis.before('NO_SUCH_CASE'), isEmpty);
    });

    test('each entry carries the full validated record', () {
      final analysis =
          service.chronologicalAnalysis(['KESAVANANDA', 'GOLAKNATH']);
      for (final e in analysis.entries) {
        expect(e.caseObject.caseId, e.caseId);
        expect(e.caseName, isNotEmpty);
      }
    });
  });

  group('B. same-year cases', () {
    test('real same-year cases order deterministically', () {
      final a =
          service.chronologicalAnalysis(['MINERVA_MILLS', 'BACHAN_SINGH']);
      final b =
          service.chronologicalAnalysis(['MINERVA_MILLS', 'BACHAN_SINGH']);
      expect(a.toJson(), b.toJson());
      expect(a.entries.map((e) => e.year).toSet(), {1980});
    });

    test('same-year ties break by judgment date then name then ID', () {
      final mid = syntheticCase(
          caseId: 'SYN_MID',
          caseName: 'B Mid',
          year: 2000,
          judgmentDate: DateTime(2000, 6, 1));
      final early = syntheticCase(
          caseId: 'SYN_EARLY',
          caseName: 'A Early',
          year: 2000,
          judgmentDate: DateTime(2000, 1, 1));
      final sameName = syntheticCase(
          caseId: 'SYN_A',
          caseName: 'A Early',
          year: 2000,
          judgmentDate: DateTime(2000, 1, 1));
      final svc = CrossCaseAnalysisService(cases: [mid, early, sameName]);
      final analysis =
          svc.chronologicalAnalysis(['SYN_MID', 'SYN_EARLY', 'SYN_A']);
      // SYN_A before SYN_EARLY by caseId tie-break, both before SYN_MID.
      expect(analysis.caseIds, ['SYN_A', 'SYN_EARLY', 'SYN_MID']);
    });
  });

  group('C. edge cases', () {
    test('empty selection yields an empty chronology', () {
      final analysis = service.chronologicalAnalysis(const []);
      expect(analysis.isEmpty, isTrue);
      expect(analysis.entries, isEmpty);
      expect(analysis.earliest, isNull);
      expect(analysis.latest, isNull);
      expect(analysis.yearSpan, isNull);
    });

    test('unresolved identifiers are reported, never fabricated', () {
      final analysis =
          service.chronologicalAnalysis(['KESAVANANDA', 'NO_SUCH_CASE', '']);
      expect(analysis.caseIds, ['KESAVANANDA']);
      expect(analysis.unresolvedCaseIds, ['NO_SUCH_CASE', '']);
    });

    test('a single case is a valid one-entry sequence', () {
      final analysis = service.chronologicalAnalysis(['GOLAKNATH']);
      expect(analysis.entries, hasLength(1));
      expect(analysis.earliest!.caseId, 'GOLAKNATH');
      expect(analysis.latest!.caseId, 'GOLAKNATH');
      expect(analysis.yearSpan, 0);
    });
  });

  group('D. determinism', () {
    test('identical input yields identical output across calls', () {
      final input = [
        'MINERVA_MILLS',
        'GOLAKNATH',
        'KESAVANANDA',
        'SAJJAN_SINGH',
        'L_CHANDRA_KUMAR',
      ];
      final a = service.chronologicalAnalysis(input);
      final b = service.chronologicalAnalysis(input);
      expect(a.toJson(), b.toJson());
    });
  });

  group('E. serialization round-trip', () {
    test('chronology survives toJson/fromJson unchanged', () {
      final analysis = service
          .chronologicalAnalysis(['MINERVA_MILLS', 'GOLAKNATH', 'KESAVANANDA']);
      final restored = ChronologyAnalysis.fromJson(analysis.toJson());
      expect(restored.toJson(), analysis.toJson());
    });
  });
}
