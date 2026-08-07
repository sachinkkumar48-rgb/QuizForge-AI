library;

import '../domain/entities/committee_enums.dart';
import '../domain/entities/committee_knowledge_object.dart';

/// Search query payload for multi-dimensional filtering over Committees.
class CommitteeSearchQuery {
  final String? name;
  final String? chairperson;
  final String? member;
  final int? year;
  final CommitteeCategory? category;
  final String? recommendation;
  final String? ministry;
  final String? article;
  final String? act;
  final String? report;
  final String? scheme;
  final String? currentAffairs;
  final String? keyword;

  const CommitteeSearchQuery({
    this.name,
    this.chairperson,
    this.member,
    this.year,
    this.category,
    this.recommendation,
    this.ministry,
    this.article,
    this.act,
    this.report,
    this.scheme,
    this.currentAffairs,
    this.keyword,
  });
}

/// Production search engine executing multi-dimensional queries and autocomplete suggestions.
class CommitteeSearchEngine {
  static List<CommitteeKnowledgeObject> search({
    required List<CommitteeKnowledgeObject> committees,
    required CommitteeSearchQuery query,
  }) {
    return committees.where((c) {
      if (query.name != null && query.name!.isNotEmpty) {
        final lower = query.name!.toLowerCase();
        final match = c.officialName.toLowerCase().contains(lower) ||
            c.shortName.toLowerCase().contains(lower);
        if (!match) return false;
      }

      if (query.chairperson != null && query.chairperson!.isNotEmpty) {
        if (!c.chairperson.name.toLowerCase().contains(query.chairperson!.toLowerCase())) {
          return false;
        }
      }

      if (query.member != null && query.member!.isNotEmpty) {
        final lower = query.member!.toLowerCase();
        final match = c.members.any((m) => m.name.toLowerCase().contains(lower));
        if (!match) return false;
      }

      if (query.year != null && c.yearConstituted != query.year) {
        return false;
      }

      if (query.category != null && c.category != query.category) {
        return false;
      }

      if (query.ministry != null && query.ministry!.isNotEmpty) {
        final lower = query.ministry!.toLowerCase();
        final match = c.constitutingAuthority.toLowerCase().contains(lower) ||
            c.relatedMinistries.any((m) => m.toLowerCase().contains(lower));
        if (!match) return false;
      }

      if (query.act != null && query.act!.isNotEmpty) {
        final lower = query.act!.toLowerCase();
        final match = c.relatedActIds.any((a) => a.toLowerCase().contains(lower)) ||
            c.recommendations.any((r) => r.relatedActIds.any((ra) => ra.toLowerCase().contains(lower)));
        if (!match) return false;
      }

      if (query.article != null && query.article!.isNotEmpty) {
        final lower = query.article!.toLowerCase();
        final match = c.relatedArticleIds.any((a) => a.toLowerCase().contains(lower)) ||
            c.recommendations.any((r) => r.relatedArticleIds.any((ra) => ra.toLowerCase().contains(lower)));
        if (!match) return false;
      }

      if (query.scheme != null && query.scheme!.isNotEmpty) {
        final lower = query.scheme!.toLowerCase();
        final match = c.relatedSchemeNames.any((s) => s.toLowerCase().contains(lower)) ||
            c.recommendations.any((r) => r.relatedSchemeNames.any((rs) => rs.toLowerCase().contains(lower)));
        if (!match) return false;
      }

      if (query.recommendation != null && query.recommendation!.isNotEmpty) {
        final lower = query.recommendation!.toLowerCase();
        final match = c.recommendations.any((r) =>
            r.title.toLowerCase().contains(lower) ||
            r.description.toLowerCase().contains(lower));
        if (!match) return false;
      }

      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lower = query.keyword!.toLowerCase();
        final match = c.officialName.toLowerCase().contains(lower) ||
            c.shortName.toLowerCase().contains(lower) ||
            c.keywords.any((k) => k.toLowerCase().contains(lower)) ||
            c.termsOfReference.description.toLowerCase().contains(lower);
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  static List<String> autocomplete({
    required List<CommitteeKnowledgeObject> committees,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final c in committees) {
      if (c.officialName.toLowerCase().contains(lower)) suggestions.add(c.officialName);
      if (c.shortName.toLowerCase().contains(lower)) suggestions.add(c.shortName);
      if (c.chairperson.name.toLowerCase().startsWith(lower)) suggestions.add(c.chairperson.name);
      for (final kw in c.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      if (suggestions.length >= maxResults) break;
    }

    return suggestions.take(maxResults).toList();
  }
}
