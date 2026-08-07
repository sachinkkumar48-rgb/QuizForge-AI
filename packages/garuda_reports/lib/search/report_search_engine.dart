library;

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_enums.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';

/// Search query payload for multi-dimensional filtering over Reports, Indices and Surveys.
class ReportSearchQuery {
  final String? title;
  final String? publisher;
  final String? organisation;
  final String? indicator;
  final String? recommendation;
  final int? year;
  final String? keyword;
  final String? article;
  final String? act;
  final String? committee;
  final String? scheme;
  final String? currentAffairs;
  final String? pyq;
  final ReportCategory? category;
  final ReportObjectType? type;

  const ReportSearchQuery({
    this.title,
    this.publisher,
    this.organisation,
    this.indicator,
    this.recommendation,
    this.year,
    this.keyword,
    this.article,
    this.act,
    this.committee,
    this.scheme,
    this.currentAffairs,
    this.pyq,
    this.category,
    this.type,
  });
}

/// Production search engine executing multi-dimensional queries and autocomplete suggestions.
class ReportSearchEngine {
  static List<ReportKnowledgeObject> search({
    required List<ReportKnowledgeObject> reports,
    required ReportSearchQuery query,
  }) {
    return reports.where((r) {
      if (query.title != null && query.title!.isNotEmpty) {
        final lower = query.title!.toLowerCase();
        final match = r.officialTitle.toLowerCase().contains(lower) ||
            r.shortName.toLowerCase().contains(lower);
        if (!match) return false;
      }

      if (query.publisher != null && query.publisher!.isNotEmpty) {
        if (!r.publishingOrganisation
            .toLowerCase()
            .contains(query.publisher!.toLowerCase())) {
          return false;
        }
      }

      if (query.organisation != null && query.organisation!.isNotEmpty) {
        final lower = query.organisation!.toLowerCase();
        final match = r.publishingOrganisation.toLowerCase().contains(lower) ||
            r.publishingMinistry.toLowerCase().contains(lower);
        if (!match) return false;
      }

      if (query.year != null && r.publicationYear != query.year) {
        return false;
      }

      if (query.category != null && r.category != query.category) {
        return false;
      }

      if (query.act != null && query.act!.isNotEmpty) {
        final lower = query.act!.toLowerCase();
        final match =
            r.relatedActIds.any((a) => a.toLowerCase().contains(lower)) ||
                r.recommendations.any((rec) => rec.relatedActIds
                    .any((ra) => ra.toLowerCase().contains(lower)));
        if (!match) return false;
      }

      if (query.article != null && query.article!.isNotEmpty) {
        final lower = query.article!.toLowerCase();
        final match =
            r.relatedArticleIds.any((a) => a.toLowerCase().contains(lower)) ||
                r.chapters.any((c) => c.relatedArticleIds
                    .any((ca) => ca.toLowerCase().contains(lower)));
        if (!match) return false;
      }

      if (query.committee != null && query.committee!.isNotEmpty) {
        final lower = query.committee!.toLowerCase();
        final match =
            r.relatedCommitteeIds.any((c) => c.toLowerCase().contains(lower)) ||
                r.recommendations.any((rec) => rec.relatedCommitteeIds
                    .any((rc) => rc.toLowerCase().contains(lower)));
        if (!match) return false;
      }

      if (query.scheme != null && query.scheme!.isNotEmpty) {
        final lower = query.scheme!.toLowerCase();
        final match =
            r.relatedSchemeNames.any((s) => s.toLowerCase().contains(lower));
        if (!match) return false;
      }

      if (query.indicator != null && query.indicator!.isNotEmpty) {
        final lower = query.indicator!.toLowerCase();
        final match =
            r.keyIndicators.any((k) => k.toLowerCase().contains(lower)) ||
                r.importantStatistics.any((s) =>
                    s.label.toLowerCase().contains(lower) ||
                    s.note.toLowerCase().contains(lower));
        if (!match) return false;
      }

      if (query.recommendation != null && query.recommendation!.isNotEmpty) {
        final lower = query.recommendation!.toLowerCase();
        final match = r.recommendations.any((rec) =>
                rec.title.toLowerCase().contains(lower) ||
                rec.description.toLowerCase().contains(lower)) ||
            r.chapters.any((c) => c.recommendations.any((rec) =>
                rec.title.toLowerCase().contains(lower) ||
                rec.description.toLowerCase().contains(lower)));
        if (!match) return false;
      }

      if (query.currentAffairs != null && query.currentAffairs!.isNotEmpty) {
        final lower = query.currentAffairs!.toLowerCase();
        final match = r.relatedCurrentAffairsIds
            .any((ca) => ca.toLowerCase().contains(lower));
        if (!match) return false;
      }

      if (query.pyq != null && query.pyq!.isNotEmpty) {
        final lower = query.pyq!.toLowerCase();
        final match =
            r.relatedPyqIds.any((p) => p.toLowerCase().contains(lower));
        if (!match) return false;
      }

      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lower = query.keyword!.toLowerCase();
        final match = r.officialTitle.toLowerCase().contains(lower) ||
            r.shortName.toLowerCase().contains(lower) ||
            r.executiveSummary.toLowerCase().contains(lower) ||
            r.keywords.any((k) => k.toLowerCase().contains(lower));
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  static List<IndexKnowledgeObject> searchIndices({
    required List<IndexKnowledgeObject> indices,
    required ReportSearchQuery query,
  }) {
    return indices.where((i) {
      if (query.title != null && query.title!.isNotEmpty) {
        if (!i.indexName.toLowerCase().contains(query.title!.toLowerCase())) {
          return false;
        }
      }

      if (query.publisher != null && query.publisher!.isNotEmpty) {
        if (!i.publisher
            .toLowerCase()
            .contains(query.publisher!.toLowerCase())) {
          return false;
        }
      }

      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lower = query.keyword!.toLowerCase();
        final match = i.indexName.toLowerCase().contains(lower) ||
            i.keywords.any((k) => k.toLowerCase().contains(lower)) ||
            i.indicators.any((ind) => ind.toLowerCase().contains(lower));
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  static List<SurveyKnowledgeObject> searchSurveys({
    required List<SurveyKnowledgeObject> surveys,
    required ReportSearchQuery query,
  }) {
    return surveys.where((s) {
      if (query.title != null && query.title!.isNotEmpty) {
        final lower = query.title!.toLowerCase();
        final match = s.officialTitle.toLowerCase().contains(lower) ||
            s.shortName.toLowerCase().contains(lower);
        if (!match) return false;
      }

      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lower = query.keyword!.toLowerCase();
        final match = s.officialTitle.toLowerCase().contains(lower) ||
            s.shortName.toLowerCase().contains(lower) ||
            s.keywords.any((k) => k.toLowerCase().contains(lower));
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  static List<IndicatorKnowledgeObject> searchIndicators({
    required List<IndicatorKnowledgeObject> indicators,
    required String query,
  }) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return const [];
    return indicators.where((i) {
      return i.name.toLowerCase().contains(lower) ||
          i.definition.toLowerCase().contains(lower) ||
          i.source.toLowerCase().contains(lower) ||
          i.keywords.any((k) => k.toLowerCase().contains(lower));
    }).toList();
  }

  static List<String> autocomplete({
    required List<ReportKnowledgeObject> reports,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final r in reports) {
      if (r.officialTitle.toLowerCase().contains(lower)) {
        suggestions.add(r.officialTitle);
      }
      if (r.shortName.toLowerCase().contains(lower)) {
        suggestions.add(r.shortName);
      }
      if (r.publishingOrganisation.toLowerCase().startsWith(lower)) {
        suggestions.add(r.publishingOrganisation);
      }
      for (final kw in r.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      if (suggestions.length >= maxResults) break;
    }

    return suggestions.take(maxResults).toList();
  }

  static List<String> suggestKeywords({
    required List<ReportKnowledgeObject> reports,
    required String prefix,
    int maxResults = 10,
  }) {
    if (prefix.trim().isEmpty) return const [];
    final lower = prefix.toLowerCase().trim();
    final Set<String> suggestions = {};

    for (final r in reports) {
      for (final kw in r.keywords) {
        if (kw.toLowerCase().startsWith(lower)) suggestions.add(kw);
      }
      for (final ind in r.keyIndicators) {
        if (ind.toLowerCase().startsWith(lower)) suggestions.add(ind);
      }
      if (suggestions.length >= maxResults) break;
    }

    return suggestions.take(maxResults).toList();
  }
}
