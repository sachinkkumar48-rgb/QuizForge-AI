import 'package:meta/meta.dart';

/// Immutable domain model representing an identified skill or knowledge gap.
@immutable
class SkillGap {
  final String id;
  final String conceptId;
  final String conceptTitle;
  final String gapSeverity; // Low, Medium, High, Critical
  final String recommendedAction;
  final DateTime identifiedAt;

  const SkillGap({
    required this.id,
    required this.conceptId,
    required this.conceptTitle,
    this.gapSeverity = 'Medium',
    required this.recommendedAction,
    required this.identifiedAt,
  });

  SkillGap copyWith({
    String? id,
    String? conceptId,
    String? conceptTitle,
    String? gapSeverity,
    String? recommendedAction,
    DateTime? identifiedAt,
  }) {
    return SkillGap(
      id: id ?? this.id,
      conceptId: conceptId ?? this.conceptId,
      conceptTitle: conceptTitle ?? this.conceptTitle,
      gapSeverity: gapSeverity ?? this.gapSeverity,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      identifiedAt: identifiedAt ?? this.identifiedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conceptId': conceptId,
        'conceptTitle': conceptTitle,
        'gapSeverity': gapSeverity,
        'recommendedAction': recommendedAction,
        'identifiedAt': identifiedAt.toIso8601String(),
      };

  factory SkillGap.fromJson(Map<String, dynamic> json) => SkillGap(
        id: json['id'] as String,
        conceptId: json['conceptId'] as String,
        conceptTitle: json['conceptTitle'] as String,
        gapSeverity: json['gapSeverity'] as String? ?? 'Medium',
        recommendedAction: json['recommendedAction'] as String? ?? '',
        identifiedAt: DateTime.parse(json['identifiedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillGap &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conceptId == other.conceptId;

  @override
  int get hashCode => Object.hash(id, conceptId);
}
