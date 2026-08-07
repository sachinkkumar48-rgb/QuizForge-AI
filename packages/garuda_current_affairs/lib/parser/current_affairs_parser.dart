library;

import '../classification/current_affairs_classifier.dart';
import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/news_event.dart';

/// Ingestion parser standardizing raw official feeds into structured NewsEvent models.
class CurrentAffairsParser {
  static NewsEvent parseRawJson(Map<String, dynamic> json) {
    final headline = json['headline'] as String? ?? json['title'] as String? ?? 'Untitled Official Event';
    final summary = json['summary'] as String? ?? json['description'] as String? ?? '';
    final content = json['content'] as String? ?? summary;
    final source = json['officialSource'] as String? ?? json['source'] as String? ?? 'Official Press Release';
    final ministry = json['ministry'] as String? ?? '';

    final category = CurrentAffairsClassifier.classify(
      headline: headline,
      summary: summary,
      content: content,
      officialSource: source,
      ministry: ministry,
    );

    final pubDateStr = json['publicationDate'] as String? ?? json['date'] as String? ?? '';
    final pubDate = DateTime.tryParse(pubDateStr) ?? DateTime.now();

    final importanceStr = json['importance'] as String? ?? 'medium';
    final importance = CurrentAffairsImportance.values.firstWhere(
      (i) => i.name.toLowerCase() == importanceStr.toLowerCase(),
      orElse: () => CurrentAffairsImportance.medium,
    );

    final rawKeywords = json['keywords'] as List? ?? [];
    final keywords = rawKeywords.map((e) => e.toString()).toList();

    final rawTags = json['tags'] as List? ?? [];
    final tags = rawTags.map((e) => e.toString()).toList();

    final rawEv = json['evidenceIds'] as List? ?? [];
    final evidenceIds = rawEv.map((e) => e.toString()).toList();

    final id = json['id'] as String? ?? 'event_${DateTime.now().millisecondsSinceEpoch}_${headline.hashCode.abs()}';

    return NewsEvent(
      id: id,
      headline: headline,
      summary: summary,
      content: content,
      officialSource: source,
      sourceUrl: json['sourceUrl'] as String? ?? '',
      publicationDate: pubDate,
      category: category,
      subcategory: json['subcategory'] as String? ?? category.displayName,
      country: json['country'] as String? ?? 'India',
      state: json['state'] as String? ?? '',
      ministry: ministry,
      importance: importance,
      keywords: keywords,
      tags: tags,
      evidenceIds: evidenceIds,
      rawMetadata: json,
    );
  }
}
