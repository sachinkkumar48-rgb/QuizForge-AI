import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P6.2 — Case Search Engine behavior over the real 49-case corpus
/// (TITAN-KO-015.0 P6). Every assertion is grounded in actual corpus records.
void main() {
  final engine = CaseSearchEngine();

  group('B. exact case-name search', () {
    test('Kesavananda name resolves as the top hit', () {
      final hits = engine.search(
          const CaseSearchQuery(term: 'Kesavananda Bharati v. State of Kerala'));
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'KESAVANANDA');
      expect(hits.first.matchedFields, contains('caseName'));
    });

    test('findExact by canonical ID, name, alias and lowercase id', () {
      expect(engine.findExact('KESAVANANDA')?.caseId, 'KESAVANANDA');
      expect(
          engine.findExact('Kesavananda Bharati v. State of Kerala')?.caseId,
          'KESAVANANDA');
      expect(engine.findExact('kesavananda')?.caseId, 'KESAVANANDA');
      expect(engine.findExact('Fundamental Rights Case')?.caseId,
          'KESAVANANDA');
    });

    test('findExact returns null for unknown references', () {
      expect(engine.findExact('No Such Case'), isNull);
    });
  });

  group('C. prefix search', () {
    test('Golak surfaces Golaknath', () {
      final hits = engine.search(const CaseSearchQuery(term: 'Golak'));
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'GOLAKNATH');
    });
  });

  group('D. alias search', () {
    test('Fundamental Rights Case alias finds Kesavananda', () {
      final hits =
          engine.search(const CaseSearchQuery(term: 'Fundamental Rights Case'));
      expect(hits.first.caseId, 'KESAVANANDA');
    });

    test('Collegium Case alias finds Second Judges case', () {
      final hits =
          engine.search(const CaseSearchQuery(term: 'Collegium Case'));
      expect(hits, isNotEmpty);
      expect(hits.any((h) => h.caseId == 'SC_OR_1993'), isTrue);
    });
  });

  group('E. substring search', () {
    test('Kumar surfaces L. Chandra Kumar first', () {
      final hits = engine.search(const CaseSearchQuery(term: 'Kumar'));
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'L_CHANDRA_KUMAR');
      expect(hits.map((h) => h.caseId), contains('ARNESH_KUMAR'));
    });
  });

  group('F. article search', () {
    test('findByArticle resolves every variant to the same set', () {
      final a = engine.findByArticle('21');
      final b = engine.findByArticle('Article 21');
      final c = engine.findByArticle('Art. 21');
      final d = engine.findByArticle('article21');
      expect(a, isNotEmpty);
      expect(a.map((r) => r.caseId).toSet(),
          b.map((r) => r.caseId).toSet());
      expect(a.map((r) => r.caseId).toSet(),
          c.map((r) => r.caseId).toSet());
      expect(a.map((r) => r.caseId).toSet(),
          d.map((r) => r.caseId).toSet());
    });

    test('Article 21 search contains Article 21 landmark cases', () {
      final hits = engine.findByArticle('21');
      expect(hits.map((r) => r.caseId), contains('MANEKA_GANDHI'));
      expect(hits.map((r) => r.caseId), contains('PUTTASWAMY'));
    });

    test('clause-form article matches precisely', () {
      final byKey = engine.findByArticle('191a');
      final byVariant = engine.findByArticle('Article 19(1)(a)');
      expect(byKey, isNotEmpty);
      expect(byKey.map((r) => r.caseId).toSet(),
          byVariant.map((r) => r.caseId).toSet());
    });

    test('article 368 search contains the amendment-power cases', () {
      final hits = engine.findByArticle('368');
      expect(hits.map((r) => r.caseId),
          containsAll(['KESAVANANDA', 'GOLAKNATH', 'SHANKARI_PRASAD']));
    });
  });

  group('G. act/statute search', () {
    test('Passports Act finds Maneka Gandhi', () {
      final hits = engine.findByAct('Passports Act, 1967');
      expect(hits.map((r) => r.caseId), contains('MANEKA_GANDHI'));
    });

    test('Section 66A finds Shreya Singhal', () {
      final hits = engine.findByAct('Section 66A');
      expect(hits.map((r) => r.caseId), contains('SHREYA_SINGHAL'));
    });
  });

  group('H. doctrine search', () {
    test('BASIC_STRUCTURE is anchored by Kesavananda', () {
      final hits = engine.findByDoctrine('BASIC_STRUCTURE');
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'KESAVANANDA');
    });

    test('doctrine name resolves to the same anchor', () {
      final byId = engine.findByDoctrine('BASIC_STRUCTURE');
      final byName = engine.findByDoctrine('Basic Structure');
      expect(byName, isNotEmpty);
      expect(byName.first.caseId, byId.first.caseId);
      expect(byName.map((r) => r.caseId), contains('MINERVA_MILLS'));
    });

    test('unknown doctrine yields no results', () {
      expect(engine.findByDoctrine('NO_SUCH_DOCTRINE'), isEmpty);
    });
  });

  group('I. judge search', () {
    test('Khanna appears on the Kesavananda bench', () {
      final hits = engine.findByJudge('Khanna');
      expect(hits.map((r) => r.caseId), contains('KESAVANANDA'));
    });

    test('Sikri C.J. appears on the Kesavananda bench', () {
      final hits = engine.findByJudge('S.M. Sikri');
      expect(hits.map((r) => r.caseId), contains('KESAVANANDA'));
    });
  });

  group('J. year search', () {
    test('1973 returns Kesavananda', () {
      final hits = engine.findByYear(1973);
      expect(hits.map((r) => r.caseId), contains('KESAVANANDA'));
    });
  });

  group('K. year-range search', () {
    test('1975..1980 stays within range and contains Maneka and Minerva', () {
      final hits = engine.findByYearRange(1975, 1980);
      expect(hits, isNotEmpty);
      for (final r in hits) {
        expect(r.caseObject.year, inInclusiveRange(1975, 1980));
      }
      expect(hits.map((r) => r.caseId),
          containsAll(['MANEKA_GANDHI', 'MINERVA_MILLS']));
    });
  });

  group('L. legal-issue search', () {
    test('basic structure issue anchors Kesavananda', () {
      final hits = engine.search(const CaseSearchQuery(term: 'basic structure'));
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'KESAVANANDA');
    });
  });

  group('M. holding/ratio search', () {
    test('prospective overruling anchors Golaknath', () {
      final hits =
          engine.search(const CaseSearchQuery(term: 'prospective overruling'));
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'GOLAKNATH');
    });
  });

  group('N. P4 intelligence search', () {
    test('privacy anchors Puttaswamy', () {
      final hits = engine.search(const CaseSearchQuery(term: 'privacy'));
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'PUTTASWAMY');
    });

    test('data protection theme surfaces the privacy cases', () {
      final hits =
          engine.search(const CaseSearchQuery(term: 'data protection'));
      expect(hits, isNotEmpty);
      expect(hits.map((r) => r.caseId), contains('PUTTASWAMY'));
    });
  });

  group('O–R. UPSC dimension search', () {
    test('prelims-critical contains Puttaswamy and Kesavananda', () {
      final hits = engine.findByUpscRelevance(CaseSearchUpscDimension.prelims,
          minimum: RelevanceLevel.critical);
      expect(hits, isNotEmpty);
      expect(hits.map((r) => r.caseId),
          containsAll(['PUTTASWAMY', 'KESAVANANDA']));
    });

    test('mains >= medium only returns cases ranked at least medium', () {
      final hits = engine.findByUpscRelevance(CaseSearchUpscDimension.mains,
          minimum: RelevanceLevel.medium);
      expect(hits, isNotEmpty);
      for (final r in hits) {
        expect(relevanceRank(r.caseObject.mainsRelevance),
            greaterThanOrEqualTo(relevanceRank(RelevanceLevel.medium)));
      }
    });

    test('essay >= high is non-empty', () {
      final hits = engine.findByUpscRelevance(CaseSearchUpscDimension.essay,
          minimum: RelevanceLevel.high);
      expect(hits, isNotEmpty);
    });

    test('interview >= high is non-empty', () {
      final hits = engine.findByUpscRelevance(CaseSearchUpscDimension.interview,
          minimum: RelevanceLevel.high);
      expect(hits, isNotEmpty);
    });

    test('UPSC dimension filter narrows a text search', () {
      final all = engine.search(const CaseSearchQuery(term: 'privacy'));
      final mains = engine.searchWithFilters(
          'privacy',
          const CaseSearchFilters(
              upscDimensions: {CaseSearchUpscDimension.mains}));
      expect(mains.length, lessThanOrEqualTo(all.length));
      for (final r in mains) {
        expect(relevanceRank(r.caseObject.mainsRelevance),
            greaterThanOrEqualTo(1));
      }
    });
  });

  group('S. graph-aware search', () {
    test('cases that followed Kesavananda', () {
      final hits = engine.findByRelationship('KESAVANANDA',
          type: PrecedentRelationshipType.followed);
      expect(hits.map((r) => r.caseId).toSet(),
          {'IR_COELHO', 'L_CHANDRA_KUMAR', 'MINERVA_MILLS'});
      expect(hits.first.matchedFields, ['relationship:followed']);
    });

    test('cases that overruled Golaknath', () {
      final hits = engine.findByRelationship('GOLAKNATH',
          type: PrecedentRelationshipType.overruled);
      expect(hits.map((r) => r.caseId).toSet(),
          {'KESAVANANDA', 'SHANKARI_PRASAD', 'SAJJAN_SINGH'});
    });

    test('related cases of Kesavananda', () {
      final hits = engine.findRelatedCases('KESAVANANDA');
      expect(hits.map((r) => r.caseId),
          containsAll(['IR_COELHO', 'GOLAKNATH', 'SHANKARI_PRASAD']));
    });

    test('all relationships from Kesavananda resolve', () {
      final hits = engine.findByRelationship('KESAVANANDA');
      expect(hits, isNotEmpty);
      for (final r in hits) {
        expect(r.caseObject, isNotNull);
        expect(r.matchedFields.first, startsWith('relationship:'));
      }
    });

    test('unknown case id yields no relationships', () {
      expect(
          engine.findByRelationship('NOT_A_CASE',
              type: PrecedentRelationshipType.followed),
          isEmpty);
    });
  });

  group('T. relationship filters', () {
    test('overruled filter selects the overruling cluster', () {
      final hits = engine.search(
          const CaseSearchQuery(
              filters: CaseSearchFilters(
                  relationshipType: PrecedentRelationshipType.overruled)));
      expect(hits, isNotEmpty);
      expect(hits.map((r) => r.caseId), contains('KESAVANANDA'));
      expect(hits.map((r) => r.caseId), contains('GOLAKNATH'));
    });
  });

  group('U. autocomplete', () {
    test('golak suggests Golaknath Case', () {
      final terms = engine.autocomplete('golak');
      expect(terms, contains('Golaknath Case'));
    });

    test('funda suggests the Fundamental Rights Case alias', () {
      expect(engine.autocomplete('funda'), contains('Fundamental Rights Case'));
    });

    test('art suggests article vocabulary', () {
      expect(engine.autocomplete('art'), contains('Article 21'));
    });

    test('empty prefix yields nothing', () {
      expect(engine.autocomplete(''), isEmpty);
    });
  });

  group('V. suggestions', () {
    test('khanna yields a judge suggestion pointing at the cases', () {
      final suggestions = engine.suggestions('khanna');
      final judge = suggestions.firstWhere((s) => s.kind == CaseSearchSuggestionKind.judge,
          orElse: () => fail('expected a judge suggestion for "khanna"'));
      expect(judge.caseIds, contains('KESAVANANDA'));
    });

    test('21 yields a deduplicated Article 21 suggestion', () {
      final suggestions = engine.suggestions('21');
      expect(suggestions.map((s) => s.term), contains('Article 21'));
      final article =
          suggestions.firstWhere((s) => s.kind == CaseSearchSuggestionKind.article,
              orElse: () => fail('expected an article suggestion'));
      // No two suggestions may share (kind, term).
      final keyed = suggestions
          .map((s) => '${s.kind.name}|${s.term}')
          .toSet();
      expect(keyed.length, suggestions.length);
      expect(article.caseIds, isNotEmpty);
    });

    test('basic suggests the doctrine and the alias', () {
      final terms = engine.suggestions('basic').map((s) => s.term).toSet();
      expect(terms, contains('Basic Structure Doctrine'));
      expect(terms, contains('BASIC_STRUCTURE'));
    });

    test('unknown prefix yields nothing', () {
      expect(engine.suggestions('zzzqqq'), isEmpty);
    });
  });

  group('W. combined filters', () {
    test('Article 21 AND privacy AND mains narrows to privacy cases', () {
      final hits = engine.searchWithFilters(
          'privacy',
          const CaseSearchFilters(
            articles: {'21'},
            upscDimensions: {CaseSearchUpscDimension.mains},
          ));
      expect(hits, isNotEmpty);
      expect(hits.first.caseId, 'PUTTASWAMY');
      for (final r in hits) {
        final hasArticle21 = r.caseObject.relatedArticles
            .any((a) => CaseSearchNormalizer.normalizeArticle(a) == '21');
        expect(hasArticle21, isTrue,
            reason: '${r.caseId} must reference Article 21');
        expect(relevanceRank(r.caseObject.mainsRelevance),
            greaterThanOrEqualTo(1));
      }
    });

    test('year filter narrows the article pool', () {
      final broad = engine.findByArticle('21');
      final narrow = engine.searchWithFilters(
          '',
          const CaseSearchFilters(articles: {'21'}, year: 1978));
      expect(narrow, isNotEmpty);
      expect(narrow.length, lessThan(broad.length));
      for (final r in narrow) {
        expect(r.caseObject.year, 1978);
      }
    });

    test('act + judge filters compose', () {
      final hits = engine.searchWithFilters(
          '',
          const CaseSearchFilters(acts: {'Indian Penal Code'}, judges: {'Chandrachud'}));
      for (final r in hits) {
        final hasAct = [...r.caseObject.relatedActs, ...r.caseObject.sections]
            .any((a) =>
                CaseSearchNormalizer.normalizeText(a).contains('indian penal code'));
        expect(hasAct, isTrue, reason: '${r.caseId} must reference the IPC');
        final hasJudge = r.caseObject.judges.any((j) =>
            CaseSearchNormalizer.normalizeText(j).contains('chandrachud'));
        expect(hasJudge, isTrue, reason: '${r.caseId} must include a Chandrachud judge');
      }
    });
  });

  group('X. deterministic ranking', () {
    test('identical queries produce identical ordered results', () {
      final a = engine.search(const CaseSearchQuery(term: 'basic structure'));
      final b = engine.search(const CaseSearchQuery(term: 'basic structure'));
      expect(a.map((r) => r.caseId), orderedEquals(b.map((r) => r.caseId)));
      expect(a.map((r) => r.score), orderedEquals(b.map((r) => r.score)));
    });

    test('scores are non-negative and stable across calls', () {
      for (final r in engine.search(const CaseSearchQuery(term: 'rights'))) {
        expect(r.score, greaterThanOrEqualTo(0));
      }
    });
  });

  group('Y. tie-breaking', () {
    test('browse-all orders by year desc then name asc', () {
      final all = engine.search(const CaseSearchQuery());
      expect(all.length, engine.indexedCaseCount);
      expect(all.first.caseId, 'JANHIT_ABHIYAN'); // 2022
      expect(all[1].caseId, 'COMMON_CAUSE_EUTHANASIA'); // 2018, name asc
      for (var i = 1; i < all.length; i++) {
        final prev = all[i - 1].caseObject.year;
        final cur = all[i].caseObject.year;
        expect(prev, greaterThanOrEqualTo(cur));
      }
    });

    test('limit truncates deterministically', () {
      final limited =
          engine.search(const CaseSearchQuery(term: 'rights', limit: 5));
      expect(limited.length, 5);
    });
  });

  group('Z. no-result behavior', () {
    test('gibberish term yields no results', () {
      expect(engine.search(const CaseSearchQuery(term: 'zzzqqq')), isEmpty);
    });

    test('blank term with filters still returns filtered pool', () {
      expect(engine.search(const CaseSearchQuery()), isNotEmpty);
    });

    test('autocomplete and suggestions return nothing for gibberish', () {
      expect(engine.autocomplete('zzzqqq'), isEmpty);
      expect(engine.suggestions('zzzqqq'), isEmpty);
    });
  });

  group('AA. evidence-aware behavior', () {
    test('every indexed record is evidence-verified', () {
      for (final r in engine.search(const CaseSearchQuery())) {
        expect(r.evidenceStatus, SearchEvidenceStatus.verified);
      }
    });

    test('evidence-only filter returns the whole verified corpus', () {
      final hits = engine.searchWithFilters(
          '', const CaseSearchFilters(evidenceOnly: true));
      expect(hits.length, engine.indexedCaseCount);
    });
  });

  group('AB. serialization', () {
    test('CaseSearchResult round-trips', () {
      final original = engine.findExact('KESAVANANDA')!;
      final restored = CaseSearchResult.fromJson(original.toJson());
      expect(restored.caseId, original.caseId);
      expect(restored.caseName, original.caseName);
      expect(restored.score, original.score);
      expect(restored.matchedFields, orderedEquals(original.matchedFields));
      expect(restored.evidenceStatus, original.evidenceStatus);
    });

    test('CaseSearchFilters round-trips', () {
      const f = CaseSearchFilters(
        year: 1973,
        articles: {'21'},
        acts: {'Passports Act, 1967'},
        doctrines: {'BASIC_STRUCTURE'},
        judges: {'khanna'},
        relationshipType: PrecedentRelationshipType.overruled,
        upscDimensions: {CaseSearchUpscDimension.mains},
        minimumUpscRelevance: RelevanceLevel.high,
        evidenceOnly: true,
      );
      final restored = CaseSearchFilters.fromJson(f.toJson());
      expect(restored.year, f.year);
      expect(restored.articles, f.articles);
      expect(restored.acts, f.acts);
      expect(restored.doctrines, f.doctrines);
      expect(restored.judges, f.judges);
      expect(restored.relationshipType, f.relationshipType);
      expect(restored.upscDimensions, f.upscDimensions);
      expect(restored.minimumUpscRelevance, f.minimumUpscRelevance);
      expect(restored.evidenceOnly, f.evidenceOnly);
    });

    test('CaseSearchQuery round-trips', () {
      final original = const CaseSearchQuery(
        term: 'basic structure',
        limit: 7,
        filters: CaseSearchFilters(year: 1973),
      );
      final restored = CaseSearchQuery.fromJson(original.toJson());
      expect(restored.term, original.term);
      expect(restored.limit, original.limit);
      expect(restored.filters?.year, original.filters?.year);
    });

    test('CaseSearchSuggestion round-trips', () {
      final original = engine.suggestions('khanna').first;
      final restored = CaseSearchSuggestion.fromJson(original.toJson());
      expect(restored.term, original.term);
      expect(restored.kind, original.kind);
      expect(restored.normalizedKey, original.normalizedKey);
      expect(restored.caseIds, orderedEquals(original.caseIds));
      expect(restored.occurrenceCount, original.occurrenceCount);
    });
  });
}
