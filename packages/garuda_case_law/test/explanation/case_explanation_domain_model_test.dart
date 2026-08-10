import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P11 — `CaseExplanation` / `ExplanationSection` / `ExplanationStatement`
/// domain-model tests (TITAN-KO-015.0 P11).
///
/// The explanation model is an immutable, deterministic, provenance-preserving
/// value object. These tests pin the serialization round-trip, section
/// accessors, provenance aggregation and the invariant that every statement
/// carries non-empty source references.
void main() {
  group('A. statement invariant', () {
    test('a statement without source references is rejected by assert', () {
      expect(
        () => ExplanationStatement(
          label: 'Holding 1',
          text: 'content',
          sourceRefs: const [],
          provenance: 'p4:holdings',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a statement with source references is accepted', () {
      final s = ExplanationStatement(
        label: 'Holding 1',
        text: 'content',
        sourceRefs: const ['KESAVANANDA', 'h-1'],
        provenance: 'p4:holdings',
      );
      expect(s.sourceRefs, ['KESAVANANDA', 'h-1']);
    });
  });

  group('B. section aggregation', () {
    test('provenance is unique, sorted and joined by ;', () {
      final section = ExplanationSection(
        type: ExplanationSectionType.holdings,
        title: 'Holdings',
        statements: [
          ExplanationStatement(
            label: 'Holding 1',
            text: 'a',
            sourceRefs: const ['A'],
            provenance: 'p4:holdings; corpus:issues',
          ),
          ExplanationStatement(
            label: 'Holding 2',
            text: 'b',
            sourceRefs: const ['A'],
            provenance: 'corpus:issues',
          ),
        ],
      );
      expect(section.provenance, 'corpus:issues;p4:holdings');
      expect(section.references, ['A']);
    });

    test('references are unique and sorted', () {
      final section = ExplanationSection(
        type: ExplanationSectionType.doctrines,
        title: 'Doctrines',
        statements: [
          ExplanationStatement(
            label: 'D',
            text: 'a',
            sourceRefs: const ['B', 'A'],
            provenance: 'x',
          ),
          ExplanationStatement(
            label: 'E',
            text: 'b',
            sourceRefs: const ['A'],
            provenance: 'y',
          ),
        ],
      );
      expect(section.references, ['A', 'B']);
      expect(section.isEmpty, isFalse);
    });

    test('section serialization round-trips', () {
      final section = ExplanationSection(
        type: ExplanationSectionType.reasoning,
        title: ExplanationSectionType.reasoning.displayTitle,
        statements: [
          ExplanationStatement(
            label: 'Summary',
            text: 'a reasoned summary',
            sourceRefs: const ['A'],
            provenance: 'p4:reasoning.summary',
          ),
        ],
      );
      final restored = ExplanationSection.fromJson(section.toJson());
      expect(restored, section);
      expect(restored.type, ExplanationSectionType.reasoning);
    });
  });

  group('C. explanation accessors', () {
    final service = CaseExplanationService();

    test('sectionOf and hasSection find a present section', () {
      final explanation = service.explain('KESAVANANDA')!;
      expect(explanation.hasSection(ExplanationSectionType.identity), isTrue);
      expect(explanation.sectionOf(ExplanationSectionType.identity), isNotNull);
      expect(
          explanation
              .sectionOf(ExplanationSectionType.identity)!
              .type
              .displayTitle,
          'Case Identity');
    });

    test('explanation serialization round-trips', () {
      final explanation = service.explain('MINERVA_MILLS')!;
      final restored = CaseExplanation.fromJson(explanation.toJson());
      expect(restored, explanation);
      expect(restored.caseId, 'MINERVA_MILLS');
      expect(restored.caseName, explanation.caseName);
    });

    test('referencedIds includes the case itself and all refs, sorted', () {
      final explanation = service.explain('KESAVANANDA')!;
      final ids = explanation.referencedIds;
      // The explained case ID is always present, but it is not necessarily the
      // first element: raw references also carry normalized article keys
      // (e.g. `13`, `368`) and holding/issue/evidence/edge IDs that sort
      // lexicographically before an uppercase case ID.
      expect(ids, contains('KESAVANANDA'));
      expect(ids, contains(explanation.caseId));
      final sorted = [...ids]..sort();
      expect(ids, sorted);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('isEmpty is false for a populated explanation', () {
      expect(service.explain('KESAVANANDA')!.isEmpty, isFalse);
    });
  });

  group('D. section type vocabulary', () {
    test('every section type has a deterministic display title', () {
      final titles = {
        for (final t in ExplanationSectionType.values) t.displayTitle,
      };
      expect(titles, hasLength(ExplanationSectionType.values.length));
      expect(titles, contains('Case Identity'));
      expect(titles, contains('Cross-Case Context'));
      expect(titles, contains('Evidence & Provenance'));
    });

    test('fromName parses round-trip and defaults safely', () {
      for (final t in ExplanationSectionType.values) {
        expect(ExplanationSectionTypeExtension.fromName(t.name), t);
      }
      expect(
        ExplanationSectionTypeExtension.fromName('not-a-section'),
        ExplanationSectionType.identity,
      );
    });
  });
}
