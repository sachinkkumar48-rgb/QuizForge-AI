import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// Corpus-integrity suite for the Phase-I + Phase-II landmark case corpus.
void main() {
  final cases = CaseSeedData.cases;
  final allIds = cases.map((c) => c.caseId).toSet();

  group('Corpus Integrity - Identity & Duplicates', () {
    test('corpus contains 49 real landmark cases', () {
      expect(cases.length, equals(49));
    });

    test('no duplicate case IDs or object IDs', () {
      final caseIds = cases.map((c) => c.caseId).toList();
      final objectIds = cases.map((c) => c.objectId).toList();
      expect(caseIds.toSet().length, equals(caseIds.length));
      expect(objectIds.toSet().length, equals(objectIds.length));
    });

    test('case IDs are non-empty upper-snake identifiers', () {
      final pattern = RegExp(r'^[A-Z][A-Z0-9_]+$');
      for (final c in cases) {
        expect(c.caseId, matches(pattern),
            reason: '${c.caseName}: caseId "${c.caseId}" is malformed');
      }
    });
  });

  group('Corpus Integrity - Required Content', () {
    test('every case has a name, citation, court, bench and year', () {
      for (final c in cases) {
        expect(c.caseName.trim(), isNotEmpty, reason: c.caseId);
        expect(c.citation.trim(), isNotEmpty, reason: c.caseId);
        expect(c.court.trim(), isNotEmpty, reason: c.caseId);
        expect(c.bench.trim(), isNotEmpty, reason: c.caseId);
        expect(c.year, greaterThan(1949), reason: c.caseId);
      }
    });

    test('every case has facts, decision, ratio or summary, and significance',
        () {
      for (final c in cases) {
        expect(c.facts.trim(), isNotEmpty, reason: c.caseId);
        expect(c.decision.trim(), isNotEmpty, reason: c.caseId);
        expect(c.ratioDecidendi.isNotEmpty || c.oneLineSummary.isNotEmpty,
            isTrue,
            reason: c.caseId);
        expect(c.constitutionalSignificance.trim(), isNotEmpty,
            reason: c.caseId);
        expect(c.garudaExplanation.trim(), isNotEmpty, reason: c.caseId);
      }
    });

    test('every case carries a typed category and judgment date', () {
      for (final c in cases) {
        expect(c.caseType, isNotNull, reason: c.caseId);
        expect(c.judgmentDate.year, greaterThan(1949), reason: c.caseId);
      }
    });

    test('case IDs referenced as related cases all resolve in the corpus', () {
      final refs = <String>[
        for (final c in cases)
          ...[
            ...c.precedentsFollowed,
            ...c.precedentsOverruled,
            ...c.precedentsDistinguished,
            ...c.relatedCases,
          ],
      ];
      for (final ref in refs) {
        expect(allIds.contains(ref), isTrue,
            reason: 'Broken case reference "$ref"');
      }
    });
  });

  group('Corpus Integrity - Evidence & Official Sources', () {
    test('evidence coverage is 100% and every evidence ID resolves', () {
      expect(CaseCorpusSupport.evidenceCoverage(cases), equals(1.0));
      for (final c in cases) {
        expect(c.evidenceIds, isNotEmpty, reason: c.caseId);
        for (final e in c.evidenceIds) {
          expect(CaseOfficialSources.isRegisteredEvidence(e), isTrue,
              reason: '${c.caseId}: unregistered evidence "$e"');
          expect(CaseOfficialSources.evidenceUrlFor(e), isNotEmpty,
              reason: '${c.caseId}: no URL for "$e"');
        }
      }
    });

    test('every case has an official source and verification date', () {
      for (final c in cases) {
        expect(c.officialSource, startsWith('https://'), reason: c.caseId);
        expect(c.officialSource, isNotEmpty, reason: c.caseId);
        expect(c.lastVerifiedDate, isNotEmpty, reason: c.caseId);
        expect(c.citations, isNotEmpty, reason: c.caseId);
      }
    });
  });

  group('Corpus Integrity - Cross-Package References', () {
    test('article references use the canonical "Article N" format', () {
      // Accepts "Article 21", "Article 21A", "Article 19(1)(a)", "Article 16(4A)".
      final articlePattern = RegExp(r'^Article \d+[A-Z]?([(][A-Za-z0-9]+[)])*$');
      for (final c in cases) {
        for (final a in c.relatedArticles) {
          expect(articlePattern.hasMatch(a), isTrue,
              reason: '${c.caseId}: malformed article ref "$a"');
        }
      }
    });

    test('doctrine references use registered GARUDA doctrine IDs', () {
      const knownDoctrines = {
        'BASIC_STRUCTURE',
        'COLOURABLE_LEGISLATION',
        'ECLIPSE',
        'ESSENTIAL_RELIGIOUS_PRACTICES',
        'HARMONIOUS_CONSTRUCTION',
        'INCIDENTAL_POWERS',
        'LEGITIMATE_EXPECTATION',
        'MANIFEST_ARBITRARINESS',
        'OCCUPIED_FIELD',
        'PITH_AND_SUBSTANCE',
        'PLEASURE_DOCTRINE',
        'POLLUTER_PAYS',
        'PRECAUTIONARY_PRINCIPLE',
        'PROPORTIONALITY',
        'PROSPECTIVE_OVERRULING',
        'PUBLIC_TRUST',
        'REASONABLE_CLASSIFICATION',
        'SEVERABILITY',
        'TERRITORIAL_NEXUS',
        'WAIVER',
      };
      for (final c in cases) {
        for (final d in c.doctrines) {
          expect(knownDoctrines.contains(d), isTrue,
              reason: '${c.caseId}: unknown doctrine "$d"');
        }
      }
    });

    test('body references use the bod_ ID convention', () {
      for (final c in cases) {
        for (final b in c.relatedBodies) {
          expect(b.startsWith('bod_'), isTrue,
              reason: '${c.caseId}: malformed body ref "$b"');
        }
      }
    });
  });

  group('Corpus Integrity - Serialization', () {
    test('every case survives JSON round-trip losslessly', () {
      for (final c in cases) {
        final restored = CaseKnowledgeObject.fromJson(c.toJson());
        expect(restored.objectId, equals(c.objectId), reason: c.caseId);
        expect(restored.caseName, equals(c.caseName), reason: c.caseId);
        expect(restored.citation, equals(c.citation), reason: c.caseId);
        expect(restored.year, equals(c.year), reason: c.caseId);
        expect(restored.ratioDecidendi, equals(c.ratioDecidendi),
            reason: c.caseId);
        expect(restored.relatedArticles, equals(c.relatedArticles),
            reason: c.caseId);
        expect(restored.precedentsFollowed, equals(c.precedentsFollowed),
            reason: c.caseId);
        expect(restored.judgmentDate, equals(c.judgmentDate),
            reason: c.caseId);
        expect(restored.evidenceIds, equals(c.evidenceIds), reason: c.caseId);
        expect(restored.doctrines, equals(c.doctrines), reason: c.caseId);
      }
    });

    test('equality is keyed on the object ID', () {
      final a = cases.first;
      expect(a, equals(a));
      expect(a, isNot(equals(cases.last)));
      expect(a.hashCode, equals(a.copyWith(oneLineSummary: 'x').hashCode));
      expect(a, isNot(equals(a.copyWith(objectId: 'KO-CASE-OTHER'))));
    });
  });

  group('Corpus Integrity - No Placeholders', () {
    test('no default/placeholder text in required free-text fields', () {
      const placeholders = ['TBD', 'TODO', 'placeholder', 'Lorem', 'lorem'];
      for (final c in cases) {
        final text = [
          c.caseName,
          c.facts,
          c.decision,
          c.oneLineSummary,
          c.constitutionalSignificance,
          c.garudaExplanation,
        ].join(' ');
        for (final p in placeholders) {
          expect(text.contains(p), isFalse,
              reason: '${c.caseId}: placeholder "$p" found');
        }
      }
    });
  });
}
