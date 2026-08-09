import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P8 — JSON case rendering (TITAN-KO-015.0 P8).
///
/// JSON export must reuse the canonical `CaseKnowledgeObject.toJson()`
/// serialization — no competing model. Verifies: valid JSON, canonical
/// compatibility, field/evidence/graph/UPSC preservation, and determinism.
void main() {
  final corpus = CaseSeedData.cases;
  final kesavananda = corpus.firstWhere((c) => c.caseId == 'KESAVANANDA');

  group('1. valid JSON', () {
    test('renderString produces parseable JSON', () {
      final json = JsonCaseRenderer.renderString(kesavananda);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded, isNotEmpty);
      expect(decoded['caseId'], 'KESAVANANDA');
      expect(decoded['caseName'], 'Kesavananda Bharati v. State of Kerala');
    });

    test('renderCorpusString produces a parseable 49-case array', () {
      final json = JsonCaseRenderer.renderCorpusString(corpus);
      final decoded = jsonDecode(json) as List<dynamic>;
      expect(decoded, hasLength(49));
      expect(decoded.first, isA<Map<String, dynamic>>());
    });
  });

  group('2. canonical serialization compatibility', () {
    test('renderMap is identical to the canonical toJson map', () {
      expect(JsonCaseRenderer.renderMap(kesavananda), kesavananda.toJson());
    });

    test('renderString decodes to the canonical map', () {
      final decoded = jsonDecode(JsonCaseRenderer.renderString(kesavananda));
      expect(decoded, kesavananda.toJson());
    });

    test('corpus array preserves order and identity', () {
      final decoded = jsonDecode(JsonCaseRenderer.renderCorpusString(corpus))
          as List<dynamic>;
      expect(decoded.map((m) => (m as Map)['caseId']).toList(),
          corpus.map((c) => c.caseId).toList());
    });
  });

  group('3. field preservation', () {
    test('identity, legal and judgment fields are preserved', () {
      final m = JsonCaseRenderer.renderMap(kesavananda);
      expect(m['objectId'], kesavananda.objectId);
      expect(m['citation'], kesavananda.citation);
      expect(m['neutralCitation'], kesavananda.neutralCitation);
      expect(m['year'], kesavananda.year);
      expect(m['court'], kesavananda.court);
      expect(m['facts'], kesavananda.facts);
      expect(m['decision'], kesavananda.decision);
      expect(m['ratioDecidendi'], kesavananda.ratioDecidendi);
    });
  });

  group('4. evidence preservation', () {
    test('evidence metadata survives the round trip', () {
      final m = JsonCaseRenderer.renderMap(kesavananda);
      expect(m['evidenceIds'], kesavananda.evidenceIds);
      expect(m['officialSource'], kesavananda.officialSource);
      expect(m['primarySource'], kesavananda.primarySource);
      expect(m['lastVerifiedDate'], kesavananda.lastVerifiedDate);
      expect(m['citations'], kesavananda.citations);
      expect(m['evidenceReferences'], kesavananda.evidenceReferences);
    });
  });

  group('5. graph / precedent preservation', () {
    test('corpus-declared relationship fields are preserved', () {
      final m = JsonCaseRenderer.renderMap(kesavananda);
      expect(m['precedentsFollowed'], kesavananda.precedentsFollowed);
      expect(m['precedentsOverruled'], kesavananda.precedentsOverruled);
      expect(m['relatedCases'], kesavananda.relatedCases);
      expect(m['doctrines'], kesavananda.doctrines);
    });

    test('structured precedent relationships survive toJson', () {
      final m = JsonCaseRenderer.renderMap(kesavananda);
      final declared = kesavananda.precedentRelationships;
      if (declared.isNotEmpty) {
        final serialized = m['precedentRelationships'] as List<dynamic>;
        expect(serialized, hasLength(declared.length));
      }
    });
  });

  group('6. UPSC intelligence preservation', () {
    test('UPSC intelligence component is preserved', () {
      final m = JsonCaseRenderer.renderMap(kesavananda);
      final intel = m['judgmentIntelligence'] as Map<String, dynamic>?;
      expect(intel, isNotNull);
      expect(intel!['caseId'], 'KESAVANANDA');
      final upsc = intel['upscIntelligence'];
      if (upsc is Map<String, dynamic>) {
        expect(upsc, isNotEmpty);
        // UPSC content is preserved verbatim — never invented or rewritten.
        final intel = kesavananda.judgmentIntelligence!.upscIntelligence!;
        expect(upsc['prelimsFacts'], intel.prelimsFacts);
        expect(upsc['mainsThemes'], intel.mainsThemes);
        expect(upsc['contemporaryRelevance'], intel.contemporaryRelevance);
      }
    });

    test('case-level UPSC themes are preserved', () {
      final m = JsonCaseRenderer.renderMap(kesavananda);
      expect(m['themes'], kesavananda.themes);
      expect(m['prelimsRelevance'], kesavananda.prelimsRelevance.name);
    });
  });

  group('7. determinism', () {
    test('renderString is byte-identical across calls', () {
      expect(JsonCaseRenderer.renderString(kesavananda),
          JsonCaseRenderer.renderString(kesavananda));
    });

    test('corpus JSON is byte-identical across calls', () {
      expect(JsonCaseRenderer.renderCorpusString(corpus),
          JsonCaseRenderer.renderCorpusString(corpus));
    });
  });

  group('8. JSON does not fabricate', () {
    test('a minimal case serializes only what it carries', () {
      final c = CaseKnowledgeObject(
        objectId: 'KO-CASE-MIN',
        caseId: 'MIN',
        caseName: 'Minimal Case',
        citation: 'AIR 2025 SC MIN',
        year: 2025,
        bench: 'Bench',
        historicalContext: '',
        facts: '',
        decision: '',
        constitutionalSignificance: '',
        judgmentDate: DateTime(2025, 1, 1),
        garudaExplanation: '',
        oneLineSummary: '',
        detailedSummary: '',
      );
      final m = JsonCaseRenderer.renderMap(c);
      expect(m['evidenceIds'], isEmpty);
      expect(m['precedentRelationships'], isEmpty);
      expect(m['judgmentIntelligence'], isNull);
    });
  });
}
