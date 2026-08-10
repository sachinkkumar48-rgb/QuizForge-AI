import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P11 — Relationship sections (TITAN-KO-015.0 P11).
///
/// Doctrine, Article and Act context come from P3 corpus fields; precedent
/// context comes from P5 case → case edges; related cases come from P9
/// discovery. Every statement surfaces the recorded relationship verbatim with
/// its provenance — P11 never infers a relationship.
void main() {
  final service = CaseExplanationService();

  group('A. doctrine context (P5 edges)', () {
    test('a doctrine-engaging case carries its doctrine statements', () {
      final doctrines = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.doctrines);
      expect(doctrines, isNotNull);
      // The doctrine display name is surfaced in the statement label; the
      // statement text carries the recorded P5 role verbatim.
      final labels = doctrines!.statements.map((s) => s.label).join('\n');
      expect(labels, contains('Basic Structure Doctrine'));
      for (final s in doctrines.statements) {
        expect(s.sourceRefs, contains('BASIC_STRUCTURE'));
        expect(s.provenance, isNotEmpty);
        expect(s.text.trim(), isNotEmpty);
      }
    });

    test('doctrine statements carry the doctrine ID, never a guessed one', () {
      final knownDoctrines = {
        for (final d in DoctrineSeedData.doctrines) d.doctrineId,
      };
      final doctrines = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.doctrines)!;
      for (final s in doctrines.statements) {
        final doctrineRefs =
            s.sourceRefs.where((r) => knownDoctrines.contains(r)).toList();
        expect(doctrineRefs, isNotEmpty,
            reason: 'a doctrine statement must reference a real doctrine ID');
      }
    });
  });

  group('B. Article context (P3 corpus)', () {
    test('referenced articles are surfaced verbatim from the corpus', () {
      final articles = service
          .explain('MANEKA_GANDHI')!
          .sectionOf(ExplanationSectionType.articles)!;
      final texts = articles.statements.map((s) => s.text).join('\n');
      expect(texts, contains('Article 14'));
      expect(texts, contains('Article 21'));
      for (final s in articles.statements) {
        expect(s.provenance, 'corpus:relatedArticles');
        expect(s.sourceRefs, contains('MANEKA_GANDHI'));
      }
    });
  });

  group('C. Act context (P3 corpus)', () {
    test('referenced Acts are surfaced verbatim from the corpus', () {
      final acts = service
          .explain('MANEKA_GANDHI')!
          .sectionOf(ExplanationSectionType.acts)!;
      final texts = acts.statements.map((s) => s.text).join('\n');
      // The Act is re-presented exactly as recorded in the corpus (including
      // its punctuation), never normalized or guessed.
      expect(texts, contains('Passports Act, 1967'));
      for (final s in acts.statements) {
        expect(s.provenance, 'corpus:relatedActs');
        expect(s.sourceRefs, contains('MANEKA_GANDHI'));
      }
    });
  });

  group('D. precedent context (P5 case → case edges)', () {
    test('a recorded overruling edge is surfaced verbatim as precedent', () {
      final precedent = service
          .explain('MANEKA_GANDHI')!
          .sectionOf(ExplanationSectionType.precedentContext)!;
      final texts = precedent.statements.map((s) => s.text).join('\n');
      expect(texts, contains('AK_GOPALAN'));
      final overruled = precedent.statements
          .where((s) => s.label.contains('overruled'))
          .toList();
      expect(overruled, isNotEmpty,
          reason: 'the P5 edge MANEKA_GANDHI overruled AK_GOPALAN is verbatim');
      for (final s in overruled) {
        // A genuine edge is referenced by its edge ID and target case ID.
        expect(s.sourceRefs.any((r) => r.startsWith('e:')), isTrue);
        expect(s.sourceRefs, contains('AK_GOPALAN'));
        expect(s.provenance, isNotEmpty);
      }
    });

    test('incoming precedent edges are surfaced with their source case', () {
      // MINERVA_MILLS followed KESAVANANDA, so KESAVANANDA has an incoming
      // followed edge from MINERVA_MILLS.
      final precedent = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.precedentContext)!;
      final texts = precedent.statements.map((s) => s.text).join('\n');
      expect(texts, contains('MINERVA_MILLS'));
    });
  });

  group('E. related cases (P9 discovery)', () {
    test('a well-connected case carries discovered related cases with reasons',
        () {
      final explanation = service.explain('KESAVANANDA')!;
      final related =
          explanation.sectionOf(ExplanationSectionType.relatedCases);
      expect(related, isNotNull);
      expect(related!.statements, isNotEmpty);
      final otherCases = service.otherCaseIds(explanation);
      expect(otherCases, isNotEmpty,
          reason: 'related cases are referenced corpus cases');
      for (final s in related.statements) {
        expect(s.label, 'Related case');
        expect(s.text.trim(), isNotEmpty);
        // Every referenced case ID is a canonical corpus case; the statement
        // traces to both the explained case (source) and the discovered case.
        final caseRefs =
            s.sourceRefs.where((r) => service.caseIds.contains(r)).toList();
        expect(caseRefs, isNotEmpty,
            reason: 'each related-case statement names a real corpus case');
        expect(caseRefs.where((r) => r != 'KESAVANANDA'), isNotEmpty,
            reason: 'each related-case statement names a distinct corpus case '
                'other than the explained case');
      }
    });

    test('related-case statements carry P9 discovery provenance', () {
      final related = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.relatedCases)!;
      for (final s in related.statements) {
        // Provenance comes from the P9 discovery reasons (graph, doctrine,
        // article or act), never from an invented source.
        expect(s.provenance, isNotEmpty);
        expect(s.sourceRefs, isNotEmpty);
      }
    });
  });
}
