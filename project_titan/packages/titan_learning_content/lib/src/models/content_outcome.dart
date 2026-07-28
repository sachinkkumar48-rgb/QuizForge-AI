import 'package:meta/meta.dart';

/// Immutable domain model representing expected learning outcomes and skill gains.
@immutable
class ContentOutcome {
  final String id;
  final String title;
  final String description;
  final double masteryGain;
  final String? skillBadge;

  const ContentOutcome({
    required this.id,
    required this.title,
    required this.description,
    this.masteryGain = 10.0,
    this.skillBadge,
  });

  ContentOutcome copyWith({
    String? id,
    String? title,
    String? description,
    double? masteryGain,
    String? skillBadge,
  }) {
    return ContentOutcome(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      masteryGain: masteryGain ?? this.masteryGain,
      skillBadge: skillBadge ?? this.skillBadge,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'masteryGain': masteryGain,
        'skillBadge': skillBadge,
      };

  factory ContentOutcome.fromJson(Map<String, dynamic> json) => ContentOutcome(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        masteryGain: (json['masteryGain'] as num? ?? 10.0).toDouble(),
        skillBadge: json['skillBadge'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentOutcome &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          masteryGain == other.masteryGain &&
          skillBadge == other.skillBadge;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        masteryGain,
        skillBadge,
      );
}
