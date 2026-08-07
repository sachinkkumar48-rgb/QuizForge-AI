library;

import 'package:meta/meta.dart';
import 'committee_enums.dart';

/// Immutable model representing a first-class structured recommendation made by a Committee.
@immutable
class Recommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final RecommendationStatus status;
  final List<String> relatedActIds;
  final List<String> relatedArticleIds;
  final List<String> relatedSchemeNames;
  final List<String> relatedPyqIds;
  final List<String> relatedCurrentAffairsIds;

  const Recommendation({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'General',
    this.status = RecommendationStatus.underConsideration,
    this.relatedActIds = const [],
    this.relatedArticleIds = const [],
    this.relatedSchemeNames = const [],
    this.relatedPyqIds = const [],
    this.relatedCurrentAffairsIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'status': status.name,
        'relatedActIds': relatedActIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
      };

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        status: RecommendationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => RecommendationStatus.underConsideration,
        ),
        relatedActIds:
            (json['relatedActIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedArticleIds:
            (json['relatedArticleIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedSchemeNames:
            (json['relatedSchemeNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedPyqIds:
            (json['relatedPyqIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedCurrentAffairsIds:
            (json['relatedCurrentAffairsIds'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );
}
