library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';

class CurrentAffairsSearchQuery {
  final DateTime? startDate;
  final DateTime? endDate;
  final CurrentAffairsCategory? category;
  final String? topic;
  final String? ministry;
  final String? state;
  final String? country;
  final String? scheme;
  final String? act;
  final String? article;
  final String? caseLaw;
  final String? doctrine;
  final String? committee;
  final String? keyword;
  final double? minRelevanceScore;

  const CurrentAffairsSearchQuery({
    this.startDate,
    this.endDate,
    this.category,
    this.topic,
    this.ministry,
    this.state,
    this.country,
    this.scheme,
    this.act,
    this.article,
    this.caseLaw,
    this.doctrine,
    this.committee,
    this.keyword,
    this.minRelevanceScore,
  });
}

class CurrentAffairsSearchEngine {
  static List<CurrentAffairsKnowledgeObject> search({
    required List<CurrentAffairsKnowledgeObject> objects,
    required CurrentAffairsSearchQuery query,
  }) {
    return objects.where((obj) {
      if (query.startDate != null && obj.publicationDate.isBefore(query.startDate!)) {
        return false;
      }

      if (query.endDate != null && obj.publicationDate.isAfter(query.endDate!)) {
        return false;
      }

      if (query.category != null && obj.category != query.category) {
        return false;
      }

      if (query.ministry != null &&
          query.ministry!.isNotEmpty &&
          !obj.ministry.toLowerCase().contains(query.ministry!.toLowerCase())) {
        return false;
      }

      if (query.state != null &&
          query.state!.isNotEmpty &&
          !obj.state.toLowerCase().contains(query.state!.toLowerCase())) {
        return false;
      }

      if (query.country != null &&
          query.country!.isNotEmpty &&
          !obj.country.toLowerCase().contains(query.country!.toLowerCase())) {
        return false;
      }

      if (query.minRelevanceScore != null &&
          obj.intelligence.relevanceScore < query.minRelevanceScore!) {
        return false;
      }

      if (query.act != null && query.act!.isNotEmpty) {
        final match = obj.links.actIds
            .any((a) => a.toLowerCase().contains(query.act!.toLowerCase()));
        if (!match) return false;
      }

      if (query.article != null && query.article!.isNotEmpty) {
        final match = obj.links.articleIds
            .any((a) => a.toLowerCase().contains(query.article!.toLowerCase()));
        if (!match) return false;
      }

      if (query.caseLaw != null && query.caseLaw!.isNotEmpty) {
        final match = obj.links.caseLawIds
            .any((c) => c.toLowerCase().contains(query.caseLaw!.toLowerCase()));
        if (!match) return false;
      }

      if (query.doctrine != null && query.doctrine!.isNotEmpty) {
        final match = obj.links.doctrineIds
            .any((d) => d.toLowerCase().contains(query.doctrine!.toLowerCase()));
        if (!match) return false;
      }

      if (query.committee != null && query.committee!.isNotEmpty) {
        final match = obj.links.committeeNames
            .any((c) => c.toLowerCase().contains(query.committee!.toLowerCase()));
        if (!match) return false;
      }

      if (query.scheme != null && query.scheme!.isNotEmpty) {
        final match = obj.links.schemeNames
            .any((s) => s.toLowerCase().contains(query.scheme!.toLowerCase()));
        if (!match) return false;
      }

      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final kw = query.keyword!.toLowerCase();
        final match = obj.headline.toLowerCase().contains(kw) ||
            obj.summary.toLowerCase().contains(kw) ||
            obj.content.toLowerCase().contains(kw) ||
            obj.keywords.any((k) => k.toLowerCase().contains(kw)) ||
            obj.tags.any((t) => t.toLowerCase().contains(kw));
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  static List<String> autocomplete({
    required List<CurrentAffairsKnowledgeObject> objects,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final obj in objects) {
      if (obj.headline.toLowerCase().contains(lower)) suggestions.add(obj.headline);
      for (final kw in obj.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      for (final act in obj.links.actIds) {
        if (act.toLowerCase().contains(lower)) suggestions.add(act);
      }
      for (final art in obj.links.articleIds) {
        if (art.toLowerCase().contains(lower)) suggestions.add(art);
      }
      if (suggestions.length >= maxResults) break;
    }

    return suggestions.take(maxResults).toList();
  }
}
