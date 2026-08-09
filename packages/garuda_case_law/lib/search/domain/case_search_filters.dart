/// Composable, evidence-aware search filters (TITAN-KO-015.0 P6).
///
/// A filter set is applied orthogonally on top of a text query: every filter
/// must hold for a case to be returned, so combined filters *narrow* results
/// rather than performing unrelated independent searches (e.g. Article 21 AND
/// privacy AND UPSC Mains).
///
/// Filters only select among existing verified records. They never create or
/// assert new legal facts.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_enums.dart'
    show PrecedentRelationshipType, RelevanceLevel;
import 'case_search_enums.dart';

/// Immutable filter set applied to a [CaseSearchQuery].
@immutable
class CaseSearchFilters {
  /// Exact judgment year.
  final int? year;

  /// Inclusive lower bound of the judgment year range.
  final int? yearFrom;

  /// Inclusive upper bound of the judgment year range.
  final int? yearTo;

  /// Court name (matched case-insensitively, e.g. "supreme court of india").
  final String? court;

  /// Constitutional article keys, normalized (e.g. `21`, `191a`, `368`).
  final Set<String> articles;

  /// Acts / statutes, normalized (e.g. `passports act 1967`).
  final Set<String> acts;

  /// Doctrine IDs or names (e.g. `BASIC_STRUCTURE` / `basic structure`).
  final Set<String> doctrines;

  /// Judge names or fragments (e.g. `khanna`).
  final Set<String> judges;

  /// Restrict to a single precedent relationship type (graph-aware).
  final PrecedentRelationshipType? relationshipType;

  /// Restrict to cases relevant to at least one of these UPSC dimensions.
  final Set<CaseSearchUpscDimension> upscDimensions;

  /// Minimum [RelevanceLevel] a case must hold on every requested UPSC
  /// dimension. When null, any non-`notApplicable` level is accepted.
  final RelevanceLevel? minimumUpscRelevance;

  /// When true, only cases with verified evidence posture are returned.
  final bool evidenceOnly;

  const CaseSearchFilters({
    this.year,
    this.yearFrom,
    this.yearTo,
    this.court,
    this.articles = const {},
    this.acts = const {},
    this.doctrines = const {},
    this.judges = const {},
    this.relationshipType,
    this.upscDimensions = const {},
    this.minimumUpscRelevance,
    this.evidenceOnly = false,
  });

  /// Whether no filter constrains the search.
  bool get isEmpty =>
      year == null &&
      yearFrom == null &&
      yearTo == null &&
      court == null &&
      articles.isEmpty &&
      acts.isEmpty &&
      doctrines.isEmpty &&
      judges.isEmpty &&
      relationshipType == null &&
      upscDimensions.isEmpty &&
      minimumUpscRelevance == null &&
      !evidenceOnly;

  /// Whether [year] falls inside the requested year / year-range window.
  bool matchesYear(int year) {
    if (this.year != null && year != this.year) return false;
    if (yearFrom != null && year < yearFrom!) return false;
    if (yearTo != null && year > yearTo!) return false;
    return true;
  }

  CaseSearchFilters copyWith({
    int? year,
    int? yearFrom,
    int? yearTo,
    String? court,
    Set<String>? articles,
    Set<String>? acts,
    Set<String>? doctrines,
    Set<String>? judges,
    PrecedentRelationshipType? relationshipType,
    Set<CaseSearchUpscDimension>? upscDimensions,
    RelevanceLevel? minimumUpscRelevance,
    bool? evidenceOnly,
  }) =>
      CaseSearchFilters(
        year: year ?? this.year,
        yearFrom: yearFrom ?? this.yearFrom,
        yearTo: yearTo ?? this.yearTo,
        court: court ?? this.court,
        articles: articles ?? this.articles,
        acts: acts ?? this.acts,
        doctrines: doctrines ?? this.doctrines,
        judges: judges ?? this.judges,
        relationshipType: relationshipType ?? this.relationshipType,
        upscDimensions: upscDimensions ?? this.upscDimensions,
        minimumUpscRelevance:
            minimumUpscRelevance ?? this.minimumUpscRelevance,
        evidenceOnly: evidenceOnly ?? this.evidenceOnly,
      );

  Map<String, dynamic> toJson() => {
        if (year != null) 'year': year,
        if (yearFrom != null) 'yearFrom': yearFrom,
        if (yearTo != null) 'yearTo': yearTo,
        if (court != null) 'court': court,
        'articles': articles.toList()..sort(),
        'acts': acts.toList()..sort(),
        'doctrines': doctrines.toList()..sort(),
        'judges': judges.toList()..sort(),
        if (relationshipType != null) 'relationshipType': relationshipType!.name,
        'upscDimensions': upscDimensions.map((e) => e.name).toList()..sort(),
        if (minimumUpscRelevance != null)
          'minimumUpscRelevance': minimumUpscRelevance!.name,
        'evidenceOnly': evidenceOnly,
      };

  factory CaseSearchFilters.fromJson(Map<String, dynamic> json) =>
      CaseSearchFilters(
        year: json['year'] as int?,
        yearFrom: json['yearFrom'] as int?,
        yearTo: json['yearTo'] as int?,
        court: json['court'] as String?,
        articles: (json['articles'] as List? ?? const []).cast<String>().toSet(),
        acts: (json['acts'] as List? ?? const []).cast<String>().toSet(),
        doctrines: (json['doctrines'] as List? ?? const []).cast<String>().toSet(),
        judges: (json['judges'] as List? ?? const []).cast<String>().toSet(),
        relationshipType: json['relationshipType'] == null
            ? null
            : PrecedentRelationshipType.values.firstWhere(
                (e) => e.name == json['relationshipType'],
                orElse: () => PrecedentRelationshipType.related,
              ),
        upscDimensions: (json['upscDimensions'] as List? ?? const [])
            .map((e) => CaseSearchUpscDimension.values.firstWhere(
                  (d) => d.name == e,
                  orElse: () => CaseSearchUpscDimension.mains,
                ))
            .toSet(),
        minimumUpscRelevance: json['minimumUpscRelevance'] == null
            ? null
            : RelevanceLevel.values.firstWhere(
                (e) => e.name == json['minimumUpscRelevance'],
                orElse: () => RelevanceLevel.high,
              ),
        evidenceOnly: json['evidenceOnly'] as bool? ?? false,
      );
}
