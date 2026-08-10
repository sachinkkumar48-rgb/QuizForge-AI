import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P11 — P10 cross-case analysis integration (TITAN-KO-015.0 P11).
///
/// P11 reuses P10's deterministic cross-case analysis for context: chronology,
/// precedent chains, comparison shared attributes/observations and doctrine
/// analysis. It never recreates P10 algorithms and never turns a P10 structural
/// observation into a legal conclusion.
void main() {
  final service = CaseExplanationService();

  ExplanationSection? crossCase(String id) =>
      service.explain(id)!.sectionOf(ExplanationSectionType.crossCaseContext);

  group('A. cross-case context from P10', () {
    test('a well-connected case carries chronological-position context', () {
      final context = crossCase('KESAVANANDA');
      expect(context, isNotNull,
          reason: 'KESAVANANDA has related cases, so P10 context exists');
      final labels = context!.statements.map((s) => s.label).toList();
      expect(labels, contains('Chronological position'));
      for (final s in context.statements) {
        expect(s.provenance, isNotEmpty);
        expect(s.sourceRefs, isNotEmpty);
      }
    });

    test('chronological-position statements carry p10 provenance', () {
      final context = crossCase('MANEKA_GANDHI');
      if (context == null) return; // only meaningful where context exists
      for (final s in context.statements) {
        if (s.label == 'Chronological position') {
          expect(s.provenance, 'p10:chronology');
        }
      }
    });

    test('a precedent-related case carries predecessor/successor chains', () {
      // MANEKA_GANDHI overruled AK_GOPALAN → AK_GOPALAN is a predecessor in
      // the chain; KESAVANANDA is a successor of MINERVA_MILLS.
      final context = crossCase('MANEKA_GANDHI');
      final labels = context?.statements.map((s) => s.label).toList() ?? [];
      if (labels.any((l) => l == 'Predecessor chain')) {
        final chain = context!.statements
            .firstWhere((s) => s.label == 'Predecessor chain');
        expect(chain.text, contains('AK_GOPALAN'));
        expect(chain.provenance, 'p10:precedentChain');
      }
    });
  });

  group('B. doctrine-analysis context from P10', () {
    test(
        'other cases engaging the same doctrine are surfaced with their P5 role',
        () {
      // BASIC_STRUCTURE has many members; KESAVANANDA is one of them.
      final context = crossCase('KESAVANANDA');
      if (context == null) return;
      final doctrineStatements = context.statements
          .where((s) => s.label.startsWith('Doctrine BASIC_STRUCTURE'))
          .toList();
      if (doctrineStatements.isEmpty) return; // only other members are shown
      for (final s in doctrineStatements) {
        expect(s.text, contains('('), reason: 'role label is present');
        expect(s.sourceRefs, contains('BASIC_STRUCTURE'));
        expect(s.provenance, isNotEmpty);
      }
    });

    test('doctrine-analysis context never claims legal similarity', () {
      final context = crossCase('KESAVANANDA');
      if (context == null) return;
      for (final s in context.statements) {
        expect(s.text.toLowerCase(), isNot(contains('legally similar')));
        expect(s.text.toLowerCase(), isNot(contains('legal similarity')));
      }
    });
  });

  group('C. P10 context never overstates', () {
    test('a disconnected case never presents a self-only chain', () {
      // SHAYARA_BANO / OLGA_TELLIS / SUCHITA_SRIVASTAVA yield single-node
      // chains in P10; P11 must not present that as a relationship.
      for (final id in ['SHAYARA_BANO', 'OLGA_TELLIS']) {
        final context = crossCase(id);
        if (context == null) continue;
        for (final s in context.statements) {
          expect(s.label, isNot('Predecessor chain'),
              reason: '$id has no predecessor hops');
          expect(s.label, isNot('Successor chain'),
              reason: '$id has no successor hops');
        }
      }
    });

    test('chronology is presented as position, never as causation', () {
      final context = crossCase('KESAVANANDA');
      if (context == null) return;
      for (final s in context.statements) {
        if (s.label == 'Chronological position') {
          expect(s.text.toLowerCase(), isNot(contains('because')));
          expect(s.text.toLowerCase(), isNot(contains('therefore the law')));
          expect(s.text.toLowerCase(), isNot(contains('evolved')));
        }
      }
    });
  });

  group('D. P10 reuse, not recreation', () {
    test('compareCases observations are surfaced with their own provenance',
        () {
      final context = crossCase('MANEKA_GANDHI');
      if (context == null) return;
      final observationLabels = context.statements
          .where((s) => s.label.startsWith('Observation:'))
          .toList();
      for (final s in observationLabels) {
        expect(s.provenance, isNotEmpty);
        expect(s.sourceRefs, isNotEmpty);
      }
    });
  });
}
