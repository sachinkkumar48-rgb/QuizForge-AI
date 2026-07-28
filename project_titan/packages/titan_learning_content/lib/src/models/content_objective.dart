import 'package:meta/meta.dart';

/// Immutable domain model representing a specific learning objective for a content item.
@immutable
class ContentObjective {
  final String id;
  final String title;
  final String description;
  final String
      bloomsTaxonomyLevel; // 'Remember', 'Understand', 'Apply', 'Analyze', 'Evaluate', 'Create'
  final double targetMasteryScore;

  const ContentObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.bloomsTaxonomyLevel,
    this.targetMasteryScore = 80.0,
  });

  ContentObjective copyWith({
    String? id,
    String? title,
    String? description,
    String? bloomsTaxonomyLevel,
    double? targetMasteryScore,
  }) {
    return ContentObjective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bloomsTaxonomyLevel: bloomsTaxonomyLevel ?? this.bloomsTaxonomyLevel,
      targetMasteryScore: targetMasteryScore ?? this.targetMasteryScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'bloomsTaxonomyLevel': bloomsTaxonomyLevel,
        'targetMasteryScore': targetMasteryScore,
      };

  factory ContentObjective.fromJson(Map<String, dynamic> json) =>
      ContentObjective(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        bloomsTaxonomyLevel:
            json['bloomsTaxonomyLevel'] as String? ?? 'Understand',
        targetMasteryScore:
            (json['targetMasteryScore'] as num? ?? 80.0).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentObjective &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          bloomsTaxonomyLevel == other.bloomsTaxonomyLevel &&
          targetMasteryScore == other.targetMasteryScore;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        bloomsTaxonomyLevel,
        targetMasteryScore,
      );
}
