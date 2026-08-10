import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P12 — Corpus-wide verification over the full 20-doctrine canonical library
/// (TITAN-KO-015.0 P12).
///
/// Verifies that the doctrine-product layer processes every canonical doctrine,
/// that no product fabricates a case ID, doctrine ID, relationship or citation,
/// that every statement remains traceable, that sections stay in the fixed
/// deterministic order, that output is deterministic and offline — derived
/// solely from the in-memory validated corpus — and that the P5 graph is never
/// mutated.
void main() {
  final service = DoctrineKnowledgeProductService();

  group('A. every canonical doctrine resolves', () {
    test('20/20 canonical doctrines resolve to a product with identity', () {
      final all = service.buildAll();
      expect(all, hasLength(20));
      expect(service.doctrineIds, hasLength(20));
      for (final product in all) {
        expect(product.doctrineId, isNotEmpty);
        expect(product.doctrineName, isNotEmpty);
        expect(
          product.sectionOf(DoctrineSectionType.identity),
          isNotNull,
          reason: '${product.doctrineId} lacks an identity section',
        );
      }
    });

    test('every doctrine ID in the seed resolves; unknown returns null', () {
      for (final d in DoctrineSeedData.doctrines) {
        expect(service.resolveDoctrineId(d.doctrineId), d.doctrineId);
        expect(service.hasDoctrine(d.doctrineId), isTrue);
      }
      expect(service.build('NOT_A_DOCTRINE'), isNull);
      expect(service.build(''), isNull);
    });

    test('buildAll covers the seed doctrine set exactly', () {
      final seedIds = {
        for (final d in DoctrineSeedData.doctrines) d.doctrineId
      };
      final productIds = service.buildAll().map((p) => p.doctrineId).toSet();
      expect(productIds, seedIds);
    });

    test('sections stay in the fixed deterministic order for every doctrine',
        () {
      final expectedOrder = DoctrineSectionType.values;
      for (final product in service.buildAll()) {
        var cursor = 0;
        for (final t in product.sections.map((s) => s.type)) {
          final idx = expectedOrder.indexOf(t);
          expect(idx, greaterThanOrEqualTo(cursor),
              reason: '${product.doctrineId} section order not fixed');
          cursor = idx;
        }
      }
    });
  });

  group('B. member integrity', () {
    final corpusIds = {for (final c in CaseSeedData.cases) c.caseId};
    final doctrineIds = {
      for (final d in DoctrineSeedData.doctrines) d.doctrineId
    };

    test('no product references an invalid case ID', () {
      for (final product in service.buildAll()) {
        for (final id in service.referencedCaseIds(product)) {
          expect(corpusIds, contains(id),
              reason: '${product.doctrineId} references unknown case $id');
        }
      }
    });

    test('no constituent-case statement is fabricated', () {
      for (final product in service.buildAll()) {
        final section = product.sectionOf(DoctrineSectionType.constituentCases);
        if (section == null) continue;
        for (final s in section.statements) {
          // The first source ref is the member case ID; the text carries the
          // verbatim case name from the corpus.
          expect(corpusIds, contains(s.sourceRefs.first));
          expect(s.sourceRefs, anyElement(startsWith('e:')));
        }
      }
    });

    test('every statement is traceable', () {
      for (final product in service.buildAll()) {
        for (final section in product.sections) {
          for (final s in section.statements) {
            expect(s.provenance.trim(), isNotEmpty);
            expect(s.sourceRefs, isNotEmpty);
            expect(s.text.trim(), isNotEmpty);
          }
        }
      }
    });

    test('every composed statement reference is canonical', () {
      for (final product in service.buildAll()) {
        for (final section in product.sections) {
          for (final s in section.statements) {
            for (final id in s.sourceRefs) {
              final isCase = corpusIds.contains(id);
              final isDoctrine = doctrineIds.contains(id);
              final isEdge = id.startsWith('e:');
              final isEvidence = id.startsWith('ev_');
              final isHolding = id.startsWith('h-') || id.startsWith('i-');
              expect(isCase || isDoctrine || isEdge || isEvidence || isHolding,
                  isTrue,
                  reason: '$id in ${product.doctrineId}/${section.type.name} '
                      'is not a canonical ID');
            }
          }
        }
      }
    });
  });

  group('C. evidence-backed composition', () {
    test('every constituent case carries a P11 explanation', () {
      for (final product in service.buildAll()) {
        final section = product.sectionOf(DoctrineSectionType.constituentCases);
        if (section == null) continue;
        expect(product.caseExplanations, hasLength(section.statements.length),
            reason: product.doctrineId);
      }
    });

    test('chronology is present for every doctrine with members', () {
      for (final product in service.buildAll()) {
        if (product.hasSection(DoctrineSectionType.constituentCases)) {
          expect(product.hasSection(DoctrineSectionType.chronology), isTrue,
              reason: '${product.doctrineId} has members but no chronology');
        }
      }
    });
  });

  group('D. determinism and no graph mutation', () {
    test('repeated generation is identical', () {
      final a = service.buildAll().map((p) => p.toJson()).toList();
      final b = service.buildAll().map((p) => p.toJson()).toList();
      expect(a, b);
    });

    test('independent services produce identical output', () {
      final other = DoctrineKnowledgeProductService();
      final a = service.buildAll().map((p) => p.toJson()).toList();
      final b = other.buildAll().map((p) => p.toJson()).toList();
      expect(a, b);
    });

    test('building the whole library never mutates the graph', () {
      final before = service.graph.edgeCount;
      service.buildAll();
      service.buildAll();
      expect(service.graph.edgeCount, before);
    });
  });
}
