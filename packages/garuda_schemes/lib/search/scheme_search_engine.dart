library;

import '../domain/entities/scheme_beneficiary.dart';
import '../domain/entities/scheme_enums.dart';
import '../domain/entities/scheme_knowledge_object.dart';
import '../domain/entities/scheme_ministry.dart';

/// Multi-dimensional search query over the Schemes Library.
class SchemeSearchQuery {
  final String? name;
  final String? acronym;
  final SchemeMinistry? ministry;
  final String? department;
  final SchemeCategory? category;
  final SchemeSector? sector;
  final BeneficiaryGroup? beneficiary;
  final String? stateUt;
  final int? launchYear;
  final SchemeStatus? status;
  final FundingPatternType? fundingPattern;
  final String? article;
  final String? act;
  final String? committee;
  final String? report;
  final String? pyq;
  final String? currentAffairs;
  final String? relatedScheme;
  final String? keyword;

  const SchemeSearchQuery({
    this.name,
    this.acronym,
    this.ministry,
    this.department,
    this.category,
    this.sector,
    this.beneficiary,
    this.stateUt,
    this.launchYear,
    this.status,
    this.fundingPattern,
    this.article,
    this.act,
    this.committee,
    this.report,
    this.pyq,
    this.currentAffairs,
    this.relatedScheme,
    this.keyword,
  });
}

/// Production search engine executing multi-dimensional queries, prefix
/// autocomplete, keyword suggestions and related-scheme discovery.
class SchemeSearchEngine {
  SchemeSearchEngine._();

  /// Multi-field filter over the corpus.
  static List<SchemeKnowledgeObject> search({
    required List<SchemeKnowledgeObject> schemes,
    required SchemeSearchQuery query,
  }) {
    return schemes.where((s) => _matches(s, query)).toList();
  }

  static bool _matches(SchemeKnowledgeObject s, SchemeSearchQuery q) {
    if (q.name != null && q.name!.trim().isNotEmpty) {
      final lower = q.name!.toLowerCase().trim();
      final match = s.officialName.toLowerCase().contains(lower) ||
          s.shortName.toLowerCase().contains(lower);
      if (!match) return false;
    }

    if (q.acronym != null && q.acronym!.trim().isNotEmpty) {
      if (!s.shortName
          .toLowerCase()
          .contains(q.acronym!.toLowerCase().trim())) {
        return false;
      }
    }

    if (q.ministry != null && s.ministry != q.ministry) {
      return false;
    }

    if (q.department != null && q.department!.trim().isNotEmpty) {
      if (!s.department.toLowerCase().contains(q.department!.toLowerCase().trim())) {
        return false;
      }
    }

    if (q.category != null && s.category != q.category) {
      return false;
    }

    if (q.sector != null && s.sector != q.sector) {
      return false;
    }

    if (q.beneficiary != null && !s.beneficiaries.contains(q.beneficiary)) {
      return false;
    }

    if (q.stateUt != null && q.stateUt!.trim().isNotEmpty) {
      final lower = q.stateUt!.toLowerCase().trim();
      final match = s.geographicScope.any((g) => g.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.launchYear != null) {
      final year = s.launchDate?.year;
      if (year == null || year != q.launchYear) return false;
    }

    if (q.status != null && s.status != q.status) {
      return false;
    }

    if (q.fundingPattern != null &&
        s.funding.fundingPattern != q.fundingPattern) {
      return false;
    }

    if (q.article != null && q.article!.trim().isNotEmpty) {
      final lower = q.article!.toLowerCase().trim();
      final match =
          s.relatedArticleIds.any((a) => a.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.act != null && q.act!.trim().isNotEmpty) {
      final lower = q.act!.toLowerCase().trim();
      final match = s.relatedActIds.any((a) => a.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.committee != null && q.committee!.trim().isNotEmpty) {
      final lower = q.committee!.toLowerCase().trim();
      final match = s.relatedCommitteeIds
          .any((c) => c.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.report != null && q.report!.trim().isNotEmpty) {
      final lower = q.report!.toLowerCase().trim();
      final match =
          s.relatedReportIds.any((r) => r.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.pyq != null && q.pyq!.trim().isNotEmpty) {
      final lower = q.pyq!.toLowerCase().trim();
      final match = s.relatedPyqIds.any((p) => p.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.currentAffairs != null && q.currentAffairs!.trim().isNotEmpty) {
      final lower = q.currentAffairs!.toLowerCase().trim();
      final match = s.relatedCurrentAffairsIds
          .any((c) => c.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.relatedScheme != null && q.relatedScheme!.trim().isNotEmpty) {
      final lower = q.relatedScheme!.toLowerCase().trim();
      final match =
          s.relatedSchemeIds.any((r) => r.toLowerCase().contains(lower));
      if (!match) return false;
    }

    if (q.keyword != null && q.keyword!.trim().isNotEmpty) {
      final lower = q.keyword!.toLowerCase().trim();
      final match = s.officialName.toLowerCase().contains(lower) ||
          s.shortName.toLowerCase().contains(lower) ||
          s.coverage.toLowerCase().contains(lower) ||
          s.implementingAgency.toLowerCase().contains(lower) ||
          s.keywords.any((k) => k.toLowerCase().contains(lower)) ||
          s.objectives.any((o) => o.toLowerCase().contains(lower)) ||
          s.keyFeatures.any((f) => f.toLowerCase().contains(lower)) ||
          s.eligibility.any((e) => e.toLowerCase().contains(lower)) ||
          s.targetBeneficiaries.any((t) => t.toLowerCase().contains(lower));
      if (!match) return false;
    }

    return true;
  }

  /// Exact-name lookup (case-insensitive, trimmed).
  static List<SchemeKnowledgeObject> findByExactName({
    required List<SchemeKnowledgeObject> schemes,
    required String name,
  }) {
    final lower = name.toLowerCase().trim();
    return schemes
        .where((s) =>
            s.officialName.toLowerCase().trim() == lower ||
            s.shortName.toLowerCase().trim() == lower)
        .toList();
  }

  /// Prefix autocomplete over official names, short names and keywords.
  static List<String> autocomplete({
    required List<SchemeKnowledgeObject> schemes,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final s in schemes) {
      if (s.officialName.toLowerCase().startsWith(lower)) {
        suggestions.add(s.officialName);
      }
      if (s.shortName.toLowerCase().startsWith(lower)) {
        suggestions.add(s.shortName);
      }
      for (final kw in s.keywords) {
        if (kw.toLowerCase().startsWith(lower)) {
          suggestions.add(kw);
        }
      }
      if (suggestions.length >= maxResults) break;
    }
    return suggestions.take(maxResults).toList();
  }

  /// Keyword suggestions derived from the corpus keyword vocabulary.
  static List<String> suggestKeywords({
    required List<SchemeKnowledgeObject> schemes,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final s in schemes) {
      for (final kw in s.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      if (suggestions.length >= maxResults) break;
    }
    return suggestions.take(maxResults).toList();
  }

  /// Related-scheme discovery: explicit `relatedSchemeIds` first, then
  /// schemes sharing the same sector or ministry as a semantic fallback.
  static List<SchemeKnowledgeObject> relatedSchemes({
    required List<SchemeKnowledgeObject> schemes,
    required SchemeKnowledgeObject scheme,
    int maxResults = 8,
  }) {
    final explicitIds = scheme.relatedSchemeIds.toSet();
    final explicit = schemes.where((s) => explicitIds.contains(s.id)).toList();

    final seen = explicitIds.toSet();
    final semantic = schemes.where((s) {
      if (s.id == scheme.id || seen.contains(s.id)) return false;
      final sameSector = s.sector == scheme.sector;
      final sameMinistry = s.ministry == scheme.ministry;
      final sameCategory = s.category == scheme.category;
      final sharesTarget = s.beneficiaries.any(
          (b) => scheme.beneficiaries.contains(b));
      return sameSector || sameMinistry || sameCategory || sharesTarget;
    }).toList();

    final ranked = [...explicit, ...semantic];
    return ranked.take(maxResults).toList();
  }
}
