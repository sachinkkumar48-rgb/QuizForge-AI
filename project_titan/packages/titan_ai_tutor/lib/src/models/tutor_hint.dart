import 'package:meta/meta.dart';

/// Immutable domain model representing a hint provided by the AI Tutor.
@immutable
class TutorHint {
  final String id;
  final String exerciseId;
  final String hintText;
  final int hintLevel; // 1 = subtle, 2 = guided, 3 = explicit
  final bool revealsAnswer;

  const TutorHint({
    required this.id,
    required this.exerciseId,
    required this.hintText,
    this.hintLevel = 1,
    this.revealsAnswer = false,
  });

  TutorHint copyWith({
    String? id,
    String? exerciseId,
    String? hintText,
    int? hintLevel,
    bool? revealsAnswer,
  }) {
    return TutorHint(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      hintText: hintText ?? this.hintText,
      hintLevel: hintLevel ?? this.hintLevel,
      revealsAnswer: revealsAnswer ?? this.revealsAnswer,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'hintText': hintText,
        'hintLevel': hintLevel,
        'revealsAnswer': revealsAnswer,
      };

  factory TutorHint.fromJson(Map<String, dynamic> json) => TutorHint(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        hintText: json['hintText'] as String,
        hintLevel: json['hintLevel'] as int? ?? 1,
        revealsAnswer: json['revealsAnswer'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorHint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          exerciseId == other.exerciseId &&
          hintLevel == other.hintLevel;

  @override
  int get hashCode => Object.hash(id, exerciseId, hintLevel);
}
