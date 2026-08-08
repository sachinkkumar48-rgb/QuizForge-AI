library;

import '../domain/entities/body_enums.dart';
import '../domain/entities/body_knowledge_object.dart';

/// Multi-dimensional search query over the Government Bodies Library.
class BodySearchQuery {
  final String? name;
  final String? acronym;
  final BodyType? bodyType;
  final BodyCategory? category;
  final String? ministry;
  final BodyJurisdiction? jurisdiction;
  final AppointmentAuthority? appointmentAuthority;
  final int? yearEstablished;
  final BodyStatus? status;
  final UpscRelevanceLevel? upscRelevance;
  final String? keyword;
  final String? article;
  final String? act;
  final String? committee;
  final String? report;
  final String? scheme;
  final String? currentAffairs;
  final String? pyq;
  final String? relatedBody;

  const BodySearchQuery({
    this.name,
    this.acronym,
    this.bodyType,
    this.category,
    this.ministry,
    this.jurisdiction,
    this.appointmentAuthority,
    this.yearEstablished,
    this.status,
    this.upscRelevance,
    this.keyword,
    this.article,
    this.act,
    this.committee,
    this.report,
    this.scheme,
    this.currentAffairs,
    this.pyq,
    this.relatedBody,
  });
}

/// Production search engine executing multi-dimensional queries with
/// relevance ranking, prefix autocomplete, keyword suggestions and
/// related-body discovery.
class BodySearchEngine {
  BodySearchEngine._();

  /// Multi-field filter over the corpus (unordered).
  static List<BodyKnowledgeObject> search({
    required List<BodyKnowledgeObject> bodies,
    required BodySearchQuery query,
  }) {
    return bodies.where((b) => _matches(b, query)).toList();
  }

  /// Multi-field search ranked by relevance (descending score).
  static List<BodyKnowledgeObject> searchRanked({
    required List<BodyKnowledgeObject> bodies,
    required BodySearchQuery query,
    int maxResults = 50,
  }) {
    final scored = bodies
        .where((b) => _matches(b, query))
        .map((b) => (body: b, score: _relevanceScore(b, query)))
        .toList()
      ..sort((a, c) => c.score.compareTo(a.score));
    return scored.take(maxResults).map((e) => e.body).toList();
  }

  static bool _matches(BodyKnowledgeObject b, BodySearchQuery q) {
    if (q.name != null && q.name!.trim().isNotEmpty) {
      final lower = q.name!.toLowerCase().trim();
      final match = b.officialName.toLowerCase().contains(lower) ||
          b.shortName.toLowerCase().contains(lower);
      if (!match) return false;
    }

    if (q.acronym != null && q.acronym!.trim().isNotEmpty) {
      if (!b.shortName
          .toLowerCase()
          .contains(q.acronym!.toLowerCase().trim())) {
        return false;
      }
    }

    if (q.bodyType != null && b.bodyType != q.bodyType) {
      return false;
    }

    if (q.category != null && b.category != q.category) {
      return false;
    }

    if (q.ministry != null && q.ministry!.trim().isNotEmpty) {
      if (!b.parentMinistry
          .toLowerCase()
          .contains(q.ministry!.toLowerCase().trim())) {
        return false;
      }
    }

    if (q.jurisdiction != null && b.jurisdiction != q.jurisdiction) {
      return false;
    }

    if (q.appointmentAuthority != null &&
        b.appointmentAuthority != q.appointmentAuthority) {
      return false;
    }

    if (q.yearEstablished != null && b.yearEstablished != q.yearEstablished) {
      return false;
    }

    if (q.status != null && b.bodyStatus != q.status) {
      return false;
    }

    if (q.upscRelevance != null && b.upscRelevance != q.upscRelevance) {
      return false;
    }

    if (q.keyword != null && q.keyword!.trim().isNotEmpty) {
      final lower = q.keyword!.toLowerCase().trim();
      final match = b.officialName.toLowerCase().contains(lower) ||
          b.shortName.toLowerCase().contains(lower) ||
          b.mandate.toLowerCase().contains(lower) ||
          b.composition.toLowerCase().contains(lower) ||
          b.keywords.any((k) => k.toLowerCase().contains(lower)) ||
          b.powers.any((p) => p.toLowerCase().contains(lower)) ||
          b.functions.any((f) => f.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.article != null && q.article!.trim().isNotEmpty) {
      final lower = q.article!.toLowerCase().trim();
      final match = b.establishingArticleIds
              .any((a) => a.toLowerCase().contains(lower)) ||
          b.relatedArticleIds.any((a) => a.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.act != null && q.act!.trim().isNotEmpty) {
      final lower = q.act!.toLowerCase().trim();
      final match = b.establishingActIds
              .any((a) => a.toLowerCase().contains(lower)) ||
          b.relatedActIds.any((a) => a.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.committee != null && q.committee!.trim().isNotEmpty) {
      final lower = q.committee!.toLowerCase().trim();
      final match = b.relatedCommitteeIds
          .any((c) => c.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.report != null && q.report!.trim().isNotEmpty) {
      final lower = q.report!.toLowerCase().trim();
      final match =
          b.relatedReportIds.any((r) => r.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.scheme != null && q.scheme!.trim().isNotEmpty) {
      final lower = q.scheme!.toLowerCase().trim();
      final match = b.relatedSchemeIds.any((s) => s.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.currentAffairs != null && q.currentAffairs!.trim().isNotEmpty) {
      final lower = q.currentAffairs!.toLowerCase().trim();
      final match = b.relatedCurrentAffairsIds
          .any((c) => c.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.pyq != null && q.pyq!.trim().isNotEmpty) {
      final lower = q.pyq!.toLowerCase().trim();
      final match = b.relatedPyqIds.any((p) => p.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.relatedBody != null && q.relatedBody!.trim().isNotEmpty) {
      final lower = q.relatedBody!.toLowerCase().trim();
      final match = b.relatedBodyIds.any((r) => r.toLowerCase().contains(lower));
      if (!match) return false;
    }

    return true;
  }

  /// Relevance score used to rank search results: exact name/acronym matches
  /// and article/act matches outrank keyword-only matches.
  static int _relevanceScore(BodyKnowledgeObject b, BodySearchQuery q) {
    var score = 0;

    if (q.keyword != null && q.keyword!.trim().isNotEmpty) {
      final lower = q.keyword!.toLowerCase().trim();
      if (b.officialName.toLowerCase() == lower) score += 50;
      if (b.shortName.toLowerCase() == lower) score += 40;
      if (b.officialName.toLowerCase().contains(lower)) score += 10;
      if (b.shortName.toLowerCase().contains(lower)) score += 8;
      if (b.keywords.any((k) => k.toLowerCase().startsWith(lower))) score += 4;
      if (b.mandate.toLowerCase().contains(lower)) score += 2;
    }

    if (q.name != null && q.name!.trim().isNotEmpty) {
      final lower = q.name!.toLowerCase().trim();
      if (b.officialName.toLowerCase() == lower) score += 40;
      if (b.officialName.toLowerCase().contains(lower)) score += 5;
    }

    if (q.acronym != null && q.acronym!.trim().isNotEmpty) {
      final lower = q.acronym!.toLowerCase().trim();
      if (b.shortName.toLowerCase() == lower) score += 30;
    }

    if (q.article != null && b.establishingArticleIds.any((a) =>
        a.toLowerCase() == q.article!.toLowerCase().trim())) {
      score += 8;
    }

    if (q.act != null && b.establishingActIds.any((a) =>
        a.toLowerCase() == q.act!.toLowerCase().trim())) {
      score += 8;
    }

    score += b.upscRelevance == UpscRelevanceLevel.high ? 3 : 1;
    return score;
  }

  /// Exact-name lookup (case-insensitive, trimmed).
  static List<BodyKnowledgeObject> findByExactName({
    required List<BodyKnowledgeObject> bodies,
    required String name,
  }) {
    final lower = name.toLowerCase().trim();
    return bodies
        .where((b) =>
            b.officialName.toLowerCase().trim() == lower ||
            b.shortName.toLowerCase().trim() == lower)
        .toList();
  }

  /// Prefix autocomplete over official names, short names and keywords.
  static List<String> autocomplete({
    required List<BodyKnowledgeObject> bodies,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final b in bodies) {
      if (b.officialName.toLowerCase().startsWith(lower)) {
        suggestions.add(b.officialName);
      }
      if (b.shortName.toLowerCase().startsWith(lower)) {
        suggestions.add(b.shortName);
      }
      for (final kw in b.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      if (suggestions.length >= maxResults) break;
    }
    return suggestions.take(maxResults).toList();
  }

  /// Keyword suggestions derived from the corpus vocabulary.
  static List<String> suggestKeywords({
    required List<BodyKnowledgeObject> bodies,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final b in bodies) {
      for (final kw in b.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      if (suggestions.length >= maxResults) break;
    }
    return suggestions.take(maxResults).toList();
  }

  /// Related-body discovery: explicit `relatedBodyIds` first, then bodies
  /// sharing the same body type, category, jurisdiction or ministry.
  static List<BodyKnowledgeObject> relatedBodies({
    required List<BodyKnowledgeObject> bodies,
    required BodyKnowledgeObject body,
    int maxResults = 8,
  }) {
    final explicitIds = body.relatedBodyIds.toSet();
    final explicit = bodies.where((b) => explicitIds.contains(b.id)).toList();

    final seen = explicitIds.toSet();
    final semantic = bodies.where((b) {
      if (b.id == body.id || seen.contains(b.id)) return false;
      final sameType = b.bodyType == body.bodyType;
      final sameCategory = b.category == body.category;
      final sameJurisdiction = b.jurisdiction == body.jurisdiction;
      final sameOversight = b.parentMinistry.isNotEmpty &&
          body.parentMinistry.isNotEmpty &&
          b.parentMinistry == body.parentMinistry;
      return sameType || sameCategory || sameJurisdiction || sameOversight;
    }).toList();

    return [...explicit, ...semantic].take(maxResults).toList();
  }
}
