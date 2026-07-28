import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a learner's goal managed by the AI Tutor.
@immutable
class TutorGoal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> targetConceptIds;
  final TutorGoalStatus status;
  final DateTime targetDate;
  final double progressPercentage; // 0.0 to 100.0

  const TutorGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetConceptIds,
    this.status = TutorGoalStatus.inProgress,
    required this.targetDate,
    this.progressPercentage = 0.0,
  });

  TutorGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? targetConceptIds,
    TutorGoalStatus? status,
    DateTime? targetDate,
    double? progressPercentage,
  }) {
    return TutorGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetConceptIds: targetConceptIds ?? this.targetConceptIds,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'targetConceptIds': targetConceptIds,
        'status': status.name,
        'targetDate': targetDate.toIso8601String(),
        'progressPercentage': progressPercentage,
      };

  factory TutorGoal.fromJson(Map<String, dynamic> json) => TutorGoal(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        targetConceptIds:
            (json['targetConceptIds'] as List? ?? []).cast<String>(),
        status: TutorGoalStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TutorGoalStatus.inProgress,
        ),
        targetDate: DateTime.parse(json['targetDate'] as String),
        progressPercentage:
            (json['progressPercentage'] as num? ?? 0.0).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, userId, title);
}
