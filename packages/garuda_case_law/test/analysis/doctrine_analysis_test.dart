import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P10 — Doctrine-oriented analysis (TITAN-KO-015.0 P10).
///
/// Doctrine analysis uses the existing P5 case → doctrine edges and P4
/// intelligence. Doctrine roles are recorded P5 evidence and are never
/// re-derived; the analysis never claims that a doctrine "evolved from X to Y".
void main() {
  final service = CrossCaseAnalysisService();

  group('A. valid doctrine', () {
    final result = service.doctrineAnalysis('BASIC_STRUCTURE');

    test('resolves the doctrine and its canonical name', () {
      expect(result.doctrineId, 'BASIC_STRUCTURE');
      expect(result.doctrineName, 'Basic Structure Doctrine');
      expect(result.isEmpty, isFalse);
    });

    test('lists every associated case in chronological order', () {
      expect(
        result.cases.map((c) => c.caseId),
        [
          'KESAVANANDA',
          'MINERVA_MILLS',
          'SC_OR_1993',
          'SR_BOMMAI',
          'L_CHANDRA_KUMAR',
          'M_NAGARAJ',
          'IR_COELHO',
          'NJAC_2015',
        ],
      );
      expect(result.chronology.caseIds, result.cases.map((c) => c.caseId));
    });

    test('doctrine roles are recorded P5 evidence, verbatim', () {
      Map<String, String> roleByCase = {
        for (final c in result.cases) c.caseId: c.role,
      };
      expect(roleByCase['KESAVANANDA'], 'establishes');
      expect(roleByCase['MINERVA_MILLS'], 'applies');
      expect(roleByCase['IR_COELHO'], 'expands');
      expect(roleByCase['NJAC_2015'], 'follows');
      expect(roleByCase['SC_OR_1993'], 'engages');
      for (final c in result.cases) {
        expect(c.roleLabel, isNotEmpty);
        expect(c.edgeId, startsWith('e:'));
        expect(c.provenance, isNotEmpty);
      }
    });

    test('every member entry carries its P4 intelligence', () {
      for (final c in result.cases) {
        expect(c.caseObject.caseId, c.caseId);
        expect(c.holdings, isNotEmpty);
        expect(c.ratios, isNotEmpty);
      }
    });

    test('precedent edges among members are exposed verbatim', () {
      final ids = result.graphRelationships.map((e) => e.edgeId).toSet();
      expect(ids, contains('e:MINERVA_MILLS|followed|KESAVANANDA'));
      expect(ids, contains('e:IR_COELHO|followed|KESAVANANDA'));
      expect(ids, contains('e:L_CHANDRA_KUMAR|followed|KESAVANANDA'));
      for (final e in result.graphRelationships) {
        expect(e.provenance, isNotEmpty);
      }
    });

    test('a single chronological-span observation is emitted', () {
      expect(result.observations, hasLength(1));
      final obs = result.observations.single;
      expect(obs.type, StructuralObservationType.chronologicalSpan);
      expect(obs.label, 'doctrine BASIC_STRUCTURE corpus cases span 1973–2015');
    });

    test('no doctrine-evolution claim is emitted', () {
      final json = result.toJson().toString().toLowerCase();
      expect(json, isNot(contains('evolved from')));
      expect(json, isNot(contains('evolution of')));
    });
  });

  group('B. doctrine resolution', () {
    test('resolves by canonical ID or by name', () {
      final byId = service.doctrineAnalysis('BASIC_STRUCTURE');
      final byName = service.doctrineAnalysis('Basic Structure Doctrine');
      expect(byId.caseIds, byName.caseIds);
    });
  });

  group('C. single-case doctrine', () {
    test('PROSPECTIVE_OVERRULING resolves to its establishing case', () {
      final result = service.doctrineAnalysis('PROSPECTIVE_OVERRULING');
      expect(result.cases.map((c) => c.caseId), ['GOLAKNATH']);
      expect(result.cases.single.role, 'establishes');
      expect(result.chronology.earliest!.caseId, 'GOLAKNATH');
    });
  });

  group('D. empty and unknown doctrines', () {
    test('an unassociated doctrine yields an empty result', () {
      final result = service.doctrineAnalysis('ECLIPSE');
      expect(result.isEmpty, isTrue);
      expect(result.cases, isEmpty);
      expect(result.chronology.isEmpty, isTrue);
      expect(result.graphRelationships, isEmpty);
    });

    test('an unknown doctrine yields an empty result', () {
      final result = service.doctrineAnalysis('NO_SUCH_DOCTRINE');
      expect(result.isEmpty, isTrue);
      expect(result.doctrineName, isEmpty);
    });
  });

  group('E. determinism', () {
    test('identical doctrine input yields identical output', () {
      final a = service.doctrineAnalysis('BASIC_STRUCTURE');
      final b = service.doctrineAnalysis('BASIC_STRUCTURE');
      expect(a.toJson(), b.toJson());
    });
  });

  group('F. serialization round-trip', () {
    test('a doctrine analysis survives toJson/fromJson unchanged', () {
      final result = service.doctrineAnalysis('BASIC_STRUCTURE');
      final restored = DoctrineAnalysisResult.fromJson(result.toJson());
      expect(restored.toJson(), result.toJson());
    });
  });
}
