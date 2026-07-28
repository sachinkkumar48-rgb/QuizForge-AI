import 'package:meta/meta.dart';

/// Immutable domain model representing prerequisite requirements for a content item.
@immutable
class ContentPrerequisite {
  final String id;
  final String requiredContentId;
  final String title;
  final double minimumMasteryScore;
  final bool isMandatory;

  const ContentPrerequisite({
    required this.id,
    required this.requiredContentId,
    required this.title,
    this.minimumMasteryScore = 70.0,
    this.isMandatory = true,
  });

  ContentPrerequisite copyWith({
    String? id,
    String? requiredContentId,
    String? title,
    double? minimumMasteryScore,
    bool? isMandatory,
  }) {
    return ContentPrerequisite(
      id: id ?? this.id,
      requiredContentId: requiredContentId ?? this.requiredContentId,
      title: title ?? this.title,
      minimumMasteryScore: minimumMasteryScore ?? this.minimumMasteryScore,
      isMandatory: isMandatory ?? this.isMandatory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requiredContentId': requiredContentId,
        'title': title,
        'minimumMasteryScore': minimumMasteryScore,
        'isMandatory': isMandatory,
      };

  factory ContentPrerequisite.fromJson(Map<String, dynamic> json) =>
      ContentPrerequisite(
        id: json['id'] as String,
        requiredContentId: json['requiredContentId'] as String,
        title: json['title'] as String,
        minimumMasteryScore:
            (json['minimumMasteryScore'] as num? ?? 70.0).toDouble(),
        isMandatory: json['isMandatory'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentPrerequisite &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          requiredContentId == other.requiredContentId &&
          title == other.title &&
          minimumMasteryScore == other.minimumMasteryScore &&
          isMandatory == other.isMandatory;

  @override
  int get hashCode => Object.hash(
        id,
        requiredContentId,
        title,
        minimumMasteryScore,
        isMandatory,
      );
}
