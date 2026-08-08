library;

import '../domain/entities/international_enums.dart';
import '../domain/entities/international_knowledge_object.dart';

/// Multi-dimensional search query over the International Organisations Library.
class InternationalSearchQuery {
  final String? name;
  final String? acronym;
  final InternationalBodyType? bodyType;
  final InternationalCategory? category;
  final GeographicalRegion? region;
  final HeadquartersRegion? headquartersRegion;
  final int? establishedYear;
  final MembershipType? membershipType;
  final IndiaRelationshipStatus? indiaRelationship;
  final GlobalIssueArea? issueArea;
  final UpscRelevanceLevel? upscRelevance;
  final String? keyword;
  final String? treaty;
  final String? relatedOrganisation;

  const InternationalSearchQuery({
    this.name,
    this.acronym,
    this.bodyType,
    this.category,
    this.region,
    this.headquartersRegion,
    this.establishedYear,
    this.membershipType,
    this.indiaRelationship,
    this.issueArea,
    this.upscRelevance,
    this.keyword,
    this.treaty,
    this.relatedOrganisation,
  });
}

/// Production search engine executing multi-dimensional queries with
/// relevance ranking, autocomplete, keyword suggestions and related-organisation
/// discovery.
class InternationalSearchEngine {
  InternationalSearchEngine._();

  /// Multi-field filter over the corpus (unordered).
  static List<InternationalKnowledgeObject> search({
    required List<InternationalKnowledgeObject> organisations,
    required InternationalSearchQuery query,
  }) {
    return organisations.where((o) => _matches(o, query)).toList();
  }

  /// Multi-field search ranked by relevance (descending score).
  static List<InternationalKnowledgeObject> searchRanked({
    required List<InternationalKnowledgeObject> organisations,
    required InternationalSearchQuery query,
    int maxResults = 50,
  }) {
    final scored = organisations
        .where((o) => _matches(o, query))
        .map((o) => (object: o, score: _relevanceScore(o, query)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((e) => e.object).toList();
  }

  static bool _matches(
      InternationalKnowledgeObject o, InternationalSearchQuery q) {
    if (q.name != null && q.name!.trim().isNotEmpty) {
      final lower = q.name!.toLowerCase().trim();
      final match = o.officialName.toLowerCase().contains(lower) ||
          o.shortName.toLowerCase().contains(lower) ||
          o.acronym.toLowerCase().contains(lower);
      if (!match) return false;
    }

    if (q.acronym != null && q.acronym!.trim().isNotEmpty) {
      if (!o.acronym.toLowerCase().contains(q.acronym!.toLowerCase().trim())) {
        return false;
      }
    }

    if (q.bodyType != null && o.bodyType != q.bodyType) {
      return false;
    }

    if (q.category != null && o.category != q.category) {
      return false;
    }

    if (q.region != null && o.geographicalRegion != q.region) {
      return false;
    }

    if (q.headquartersRegion != null &&
        o.headquartersRegion != q.headquartersRegion) {
      return false;
    }

    if (q.establishedYear != null && o.establishedYear != q.establishedYear) {
      return false;
    }

    if (q.membershipType != null && o.membershipType != q.membershipType) {
      return false;
    }

    if (q.indiaRelationship != null &&
        o.indiaMembership != q.indiaRelationship) {
      return false;
    }

    if (q.issueArea != null && !o.issueAreas.contains(q.issueArea)) {
      return false;
    }

    if (q.upscRelevance != null && o.upscRelevance != q.upscRelevance) {
      return false;
    }

    if (q.keyword != null && q.keyword!.trim().isNotEmpty) {
      final lower = q.keyword!.toLowerCase().trim();
      final match = o.officialName.toLowerCase().contains(lower) ||
          o.shortName.toLowerCase().contains(lower) ||
          o.acronym.toLowerCase().contains(lower) ||
          o.mandate.toLowerCase().contains(lower) ||
          o.foundingTreaty.toLowerCase().contains(lower) ||
          o.keywords.any((k) => k.toLowerCase().contains(lower)) ||
          o.objectives.any((x) => x.toLowerCase().contains(lower)) ||
          o.functions.any((x) => x.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.treaty != null && q.treaty!.trim().isNotEmpty) {
      final lower = q.treaty!.toLowerCase().trim();
      final match = o.foundingTreaty.toLowerCase().contains(lower) ||
          o.importantConventions.any((c) => c.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.relatedOrganisation != null &&
        q.relatedOrganisation!.trim().isNotEmpty) {
      final lower = q.relatedOrganisation!.toLowerCase().trim();
      final match = o.relatedOrganisationIds
          .any((r) => r.toLowerCase().contains(lower));
      if (!match) return false;
    }

    return true;
  }

  /// Relevance score: exact name > acronym > name-contains > keyword >
  /// India relevance > UPSC relevance > relationship relevance.
  static int _relevanceScore(
      InternationalKnowledgeObject o, InternationalSearchQuery q) {
    var score = 0;

    if (q.keyword != null && q.keyword!.trim().isNotEmpty) {
      final lower = q.keyword!.toLowerCase().trim();
      if (o.officialName.toLowerCase() == lower) score += 60;
      if (o.acronym.toLowerCase() == lower) score += 50;
      if (o.shortName.toLowerCase() == lower) score += 40;
      if (o.officialName.toLowerCase().contains(lower)) score += 10;
      if (o.acronym.toLowerCase().contains(lower)) score += 8;
      if (o.keywords.any((k) => k.toLowerCase().startsWith(lower))) score += 4;
      if (o.mandate.toLowerCase().contains(lower)) score += 2;
    }

    if (q.name != null && q.name!.trim().isNotEmpty) {
      final lower = q.name!.toLowerCase().trim();
      if (o.officialName.toLowerCase() == lower) score += 40;
      if (o.shortName.toLowerCase() == lower) score += 20;
      if (o.officialName.toLowerCase().contains(lower)) score += 5;
    }

    if (q.acronym != null && q.acronym!.trim().isNotEmpty) {
      final lower = q.acronym!.toLowerCase().trim();
      if (o.acronym.toLowerCase() == lower) score += 30;
    }

    if (q.treaty != null &&
        o.foundingTreaty.toLowerCase() == q.treaty!.toLowerCase().trim()) {
      score += 8;
    }

    // India and UPSC relevance tie-breakers.
    if (o.indiaMembership == IndiaRelationshipStatus.foundingMember ||
        o.indiaMembership == IndiaRelationshipStatus.fullMember) {
      score += 3;
    }
    if (o.upscRelevance == UpscRelevanceLevel.high) score += 2;

    return score;
  }

  /// Exact-name lookup (case-insensitive, trimmed).
  static List<InternationalKnowledgeObject> findByExactName({
    required List<InternationalKnowledgeObject> organisations,
    required String name,
  }) {
    final lower = name.toLowerCase().trim();
    return organisations
        .where((o) =>
            o.officialName.toLowerCase().trim() == lower ||
            o.shortName.toLowerCase().trim() == lower ||
            o.acronym.toLowerCase().trim() == lower)
        .toList();
  }

  /// Prefix autocomplete over official names, acronyms and keywords.
  static List<String> autocomplete({
    required List<InternationalKnowledgeObject> organisations,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final o in organisations) {
      if (o.officialName.toLowerCase().startsWith(lower)) {
        suggestions.add(o.officialName);
      }
      if (o.acronym.toLowerCase().startsWith(lower)) {
        suggestions.add(o.acronym);
      }
      for (final kw in o.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      if (suggestions.length >= maxResults) break;
    }
    return suggestions.take(maxResults).toList();
  }

  /// Keyword suggestions derived from the corpus vocabulary.
  static List<String> suggestKeywords({
    required List<InternationalKnowledgeObject> organisations,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final o in organisations) {
      for (final kw in o.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      if (suggestions.length >= maxResults) break;
    }
    return suggestions.take(maxResults).toList();
  }

  /// Related-organisation discovery: explicit `relatedOrganisationIds` first,
  /// then organisations sharing category, region or issue areas.
  static List<InternationalKnowledgeObject> relatedOrganisations({
    required List<InternationalKnowledgeObject> organisations,
    required InternationalKnowledgeObject organisation,
    int maxResults = 8,
  }) {
    final explicitIds = organisation.relatedOrganisationIds.toSet();
    final explicit =
        organisations.where((o) => explicitIds.contains(o.id)).toList();

    final seen = explicitIds.toSet();
    final semantic = organisations.where((o) {
      if (o.id == organisation.id || seen.contains(o.id)) return false;
      final sameCategory = o.category == organisation.category;
      final sameRegion = o.geographicalRegion == organisation.geographicalRegion;
      final sharesIssue = o.issueAreas.any(
          (a) => organisation.issueAreas.contains(a));
      final sameBodyType = o.bodyType == organisation.bodyType;
      return sameCategory || sameRegion || sharesIssue || sameBodyType;
    }).toList();

    return [...explicit, ...semantic].take(maxResults).toList();
  }
}
