library;

import '../data/case_seed_data.dart';
import '../domain/entities/case_knowledge_object.dart';
import 'case_repository.dart';

/// Thread-safe offline-first repository implementation of [CaseRepository].
class InMemoryCaseRepository implements CaseRepository {
  final List<CaseKnowledgeObject> _casesList;
  final Map<String, CaseKnowledgeObject> _casesMap = {};

  InMemoryCaseRepository({
    List<CaseKnowledgeObject>? cases,
  }) : _casesList = cases ?? CaseSeedData.cases {
    for (final c in _casesList) {
      _casesMap[c.objectId.toUpperCase()] = c;
      _casesMap[c.caseId.toUpperCase()] = c;
      _casesMap[c.caseName.toUpperCase()] = c;
      _casesMap[c.citation.toUpperCase()] = c;
    }
  }

  @override
  Future<List<CaseKnowledgeObject>> getCases() async => _casesList;

  @override
  Future<CaseKnowledgeObject?> findCase(String idOrName) async {
    final raw = idOrName.trim();
    if (raw.isEmpty) return null;

    final upper = raw.toUpperCase();
    if (_casesMap.containsKey(upper)) return _casesMap[upper];
    if (_casesMap.containsKey('KO-CASE-$upper')) return _casesMap['KO-CASE-$upper'];

    final clean = raw.replaceAll(RegExp(r'^(KO-CASE-|CASE-)', caseSensitive: false), '').trim().toUpperCase();

    for (final c in _casesList) {
      if (c.caseId.toUpperCase() == clean ||
          c.objectId.toUpperCase() == upper ||
          c.objectId.toUpperCase() == 'KO-CASE-$clean' ||
          c.caseName.toUpperCase().contains(upper) ||
          c.aliases.any((alias) => alias.toUpperCase() == upper || alias.toUpperCase() == clean)) {
        return c;
      }
    }
    return null;
  }

  @override
  Future<List<CaseKnowledgeObject>> getCasesByArticle(String articleNumber) async {
    final target = articleNumber.replaceAll(RegExp(r'^(ARTICLE|ART)\s*', caseSensitive: false), '').trim().toLowerCase();
    if (target.isEmpty) return const [];

    return _casesList.where((c) {
      return c.relatedArticles.any((art) {
        final cleanArt = art.replaceAll(RegExp(r'^(ARTICLE|ART)\s*', caseSensitive: false), '').trim().toLowerCase();
        return cleanArt == target || art.toLowerCase() == target || art.toLowerCase() == 'art $target';
      });
    }).toList();
  }

  @override
  Future<List<CaseKnowledgeObject>> getCasesByAmendment(String amendment) async {
    final target = amendment.toLowerCase().trim();
    if (target.isEmpty) return const [];

    return _casesList.where((c) {
      return c.relatedAmendments.any((amd) => amd.toLowerCase().contains(target));
    }).toList();
  }

  @override
  Future<List<CaseKnowledgeObject>> getCasesByJudge(String judgeName) async {
    final target = judgeName.toLowerCase().trim();
    if (target.isEmpty) return const [];

    return _casesList.where((c) {
      return c.judges.any((j) => j.toLowerCase().contains(target));
    }).toList();
  }

  @override
  Future<List<CaseKnowledgeObject>> searchCases(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _casesList;

    return _casesList.where((c) {
      final inId = c.objectId.toLowerCase().contains(q) || c.caseId.toLowerCase().contains(q);
      final inName = c.caseName.toLowerCase().contains(q);
      final inCitation = c.citation.toLowerCase().contains(q);
      final inBench = c.bench.toLowerCase().contains(q);
      final inJudges = c.judges.any((j) => j.toLowerCase().contains(q));
      final inKeywords = c.keywords.any((k) => k.toLowerCase().contains(q));
      final inPrinciples = c.keyPrinciples.any((p) => p.toLowerCase().contains(q));
      final inRatio = c.ratioDecidendi.any((r) => r.toLowerCase().contains(q));
      final inSummary = c.oneLineSummary.toLowerCase().contains(q) || c.garudaExplanation.toLowerCase().contains(q);
      final inArticles = c.relatedArticles.any((a) => a.toLowerCase().contains(q));
      final inAmendments = c.relatedAmendments.any((a) => a.toLowerCase().contains(q));

      return inId || inName || inCitation || inBench || inJudges || inKeywords || inPrinciples || inRatio || inSummary || inArticles || inAmendments;
    }).toList();
  }
}
