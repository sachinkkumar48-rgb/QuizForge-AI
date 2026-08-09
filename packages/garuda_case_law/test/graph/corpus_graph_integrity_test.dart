import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P5 corpus-wide integrity — the graph is exactly the evidence-backed
/// projection of the corpus: no fabricated, placeholder or invented
/// relationships, and full backward compatibility with the P3 precedent data.
void main() {
  final cases = CaseSeedData.cases;
  final doctrines = DoctrineSeedData.doctrines;
  final graph = LegalGraphSeed.fromCorpus().build();
  final caseIds = cases.map((c) => c.caseId).toSet();
  final doctrineIds = doctrines.map((d) => d.doctrineId).toSet();

  group('Node integrity', () {
    test('case nodes are exactly the 49 corpus case IDs', () {
      final graphCaseIds = graph.caseNodes.map((n) => n.id).toSet();
      expect(graphCaseIds, caseIds);
    });

    test('doctrine nodes are exactly the canonical doctrine IDs', () {
      final graphDoctrineIds = graph.doctrineNodes.map((n) => n.id).toSet();
      expect(graphDoctrineIds, doctrineIds);
    });
  });

  group('Edge integrity', () {
    test('every edge references only known nodes', () {
      for (final e in graph.edges) {
        expect(graph.hasNode(e.sourceId, e.sourceNodeType),
            isTrue,
            reason: e.tripleKey);
        expect(graph.hasNode(e.targetId, e.targetNodeType),
            isTrue,
            reason: e.tripleKey);
      }
    });

    test('every provenance is a corpus or doctrine reference', () {
      final pattern = RegExp(r'^(corpus:[a-zA-Z]+|doctrine:[A-Z_]+\.\w+)$');
      for (final e in graph.edges) {
        expect(pattern.hasMatch(e.provenance),
            isTrue,
            reason: '${e.tripleKey}: ${e.provenance}');
      }
    });

    test('every edge carries registered evidence', () {
      for (final e in graph.edges) {
        for (final evidence in e.evidenceIds) {
          expect(LegalGraphSeed.isRegisteredEvidence(evidence),
              isTrue,
              reason: '${e.tripleKey}: $evidence');
        }
      }
    });

    test('the graph passes full integrity validation', () {
      final result = LegalGraphValidator.validateGraph(graph);
      expect(result.isValid, isTrue, reason: result.issues.toString());
    });
  });

  group('No fabricated relationships', () {
    test('case-case edges are exactly the corpus precedent fields', () {
      final expected = <String>{};
      for (final c in cases) {
        for (final t in c.precedentsFollowed) {
          expected.add('${c.caseId}|followed|$t');
        }
        for (final t in c.precedentsOverruled) {
          expected.add('${c.caseId}|overruled|$t');
        }
        for (final t in c.precedentsDistinguished) {
          expected.add('${c.caseId}|distinguished|$t');
        }
        for (final t in c.relatedCases) {
          expected.add('${c.caseId}|related|$t');
        }
        for (final r in c.precedentRelationships) {
          expected.add('${r.sourceCaseId}|${r.type.name}|${r.targetCaseId}');
        }
      }
      final actual =
          graph.edges.where((e) => e.isCaseCaseEdge).map((e) => e.tripleKey).toSet();
      expect(actual, expected);
    });

    test('case-doctrine edges are exactly the case fields + doctrine records',
        () {
      final roles = LegalGraphSeed.doctrineRecordRoles(
          cases: cases, doctrines: doctrines);
      final covered = <String>{
        for (final c in cases)
          for (final did in c.doctrines) '${c.caseId}|$did',
      };
      final expected = <String>{};
      for (final c in cases) {
        for (final did in c.doctrines) {
          final key = '${c.caseId}|$did';
          final role = roles[key];
          expected.add('${c.caseId}|${role?.$1.name ?? 'engages'}|$did');
        }
      }
      for (final entry in roles.entries) {
        if (covered.contains(entry.key)) continue;
        final split = entry.key.split('|');
        expected.add('${split[0]}|${entry.value.$1.name}|${split[1]}');
      }
      final actual = graph.edges
          .where((e) => e.isCaseDoctrineEdge)
          .map((e) => e.tripleKey)
          .toSet();
      expect(actual, expected);
    });

    test('no case-case edge links to a non-canonical target', () {
      for (final e in graph.edges.where((e) => e.isCaseCaseEdge)) {
        expect(caseIds.contains(e.targetId), isTrue, reason: e.tripleKey);
      }
    });

    test('no placeholder or default relationships exist', () {
      expect(graph.edges, isNotEmpty);
      for (final e in graph.edges) {
        expect(e.provenance, isNot(anyOf('', 'corpus:precedent',
            'corpus:doctrine')), reason: e.tripleKey);
      }
    });
  });

  group('Backward compatibility with P3', () {
    test('every P3 followed reference survives in the graph', () {
      for (final c in cases) {
        for (final t in c.precedentsFollowed) {
          expect(graph.hasEdge(c.caseId, 'followed', t), isTrue,
              reason: '${c.caseId} followed $t');
        }
      }
    });

    test('every P3 overruled reference survives in the graph', () {
      for (final c in cases) {
        for (final t in c.precedentsOverruled) {
          expect(graph.hasEdge(c.caseId, 'overruled', t), isTrue,
              reason: '${c.caseId} overruled $t');
        }
      }
    });

    test('every P3 distinguished reference survives in the graph', () {
      for (final c in cases) {
        for (final t in c.precedentsDistinguished) {
          expect(graph.hasEdge(c.caseId, 'distinguished', t), isTrue,
              reason: '${c.caseId} distinguished $t');
        }
      }
    });

    test('every P3 related reference survives in the graph', () {
      for (final c in cases) {
        for (final t in c.relatedCases) {
          expect(graph.hasEdge(c.caseId, 'related', t), isTrue,
              reason: '${c.caseId} related $t');
        }
      }
    });

    test('the existing corpus integrity test data is unchanged', () {
      expect(cases.length, 49);
      expect(doctrines.length, 20);
    });
  });
}
