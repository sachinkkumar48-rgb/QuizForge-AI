library;

import 'package:meta/meta.dart';
import 'current_affairs_enums.dart';

/// Immutable model representing a raw, verified event ingested from official sources.
@immutable
class NewsEvent {
  final String id;
  final String headline;
  final String summary;
  final String content;
  final String officialSource;
  final String sourceUrl;
  final DateTime publicationDate;
  final DateTime retrievedDate;
  final CurrentAffairsCategory category;
  final String subcategory;
  final String country;
  final String state;
  final String ministry;
  final CurrentAffairsImportance importance;
  final List<String> keywords;
  final List<String> tags;
  final List<String> evidenceIds;
  final Map<String, dynamic> rawMetadata;

  NewsEvent({
    required this.id,
    required this.headline,
    required this.summary,
    required this.content,
    required this.officialSource,
    this.sourceUrl = '',
    required this.publicationDate,
    DateTime? retrievedDate,
    this.category = CurrentAffairsCategory.miscellaneous,
    this.subcategory = '',
    this.country = 'India',
    this.state = '',
    this.ministry = '',
    this.importance = CurrentAffairsImportance.medium,
    this.keywords = const [],
    this.tags = const [],
    this.evidenceIds = const [],
    this.rawMetadata = const {},
  }) : retrievedDate = retrievedDate ?? DateTime.now();

  NewsEvent copyWith({
    String? id,
    String? headline,
    String? summary,
    String? content,
    String? officialSource,
    String? sourceUrl,
    DateTime? publicationDate,
    DateTime? retrievedDate,
    CurrentAffairsCategory? category,
    String? subcategory,
    String? country,
    String? state,
    String? ministry,
    CurrentAffairsImportance? importance,
    List<String>? keywords,
    List<String>? tags,
    List<String>? evidenceIds,
    Map<String, dynamic>? rawMetadata,
  }) {
    return NewsEvent(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      officialSource: officialSource ?? this.officialSource,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      publicationDate: publicationDate ?? this.publicationDate,
      retrievedDate: retrievedDate ?? this.retrievedDate,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      country: country ?? this.country,
      state: state ?? this.state,
      ministry: ministry ?? this.ministry,
      importance: importance ?? this.importance,
      keywords: keywords ?? List.from(this.keywords),
      tags: tags ?? List.from(this.tags),
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      rawMetadata: rawMetadata ?? Map.from(this.rawMetadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'headline': headline,
        'summary': summary,
        'content': content,
        'officialSource': officialSource,
        'sourceUrl': sourceUrl,
        'publicationDate': publicationDate.toIso8601String(),
        'retrievedDate': retrievedDate.toIso8601String(),
        'category': category.name,
        'subcategory': subcategory,
        'country': country,
        'state': state,
        'ministry': ministry,
        'importance': importance.name,
        'keywords': keywords,
        'tags': tags,
        'evidenceIds': evidenceIds,
        'rawMetadata': rawMetadata,
      };

  factory NewsEvent.fromJson(Map<String, dynamic> json) => NewsEvent(
        id: json['id'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        content: json['content'] as String? ?? '',
        officialSource: json['officialSource'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        publicationDate:
            DateTime.tryParse(json['publicationDate'] as String? ?? '') ?? DateTime.now(),
        retrievedDate:
            DateTime.tryParse(json['retrievedDate'] as String? ?? '') ?? DateTime.now(),
        category: CurrentAffairsCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => CurrentAffairsCategory.miscellaneous,
        ),
        subcategory: json['subcategory'] as String? ?? '',
        country: json['country'] as String? ?? 'India',
        state: json['state'] as String? ?? '',
        ministry: json['ministry'] as String? ?? '',
        importance: CurrentAffairsImportance.values.firstWhere(
          (i) => i.name == json['importance'],
          orElse: () => CurrentAffairsImportance.medium,
        ),
        keywords: (json['keywords'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        evidenceIds:
            (json['evidenceIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        rawMetadata: Map<String, dynamic>.from(json['rawMetadata'] as Map? ?? {}),
      );
}
