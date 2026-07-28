import 'package:meta/meta.dart';

/// Immutable domain model representing feedback given by the learner or tutor.
@immutable
class TutorFeedback {
  final String id;
  final bool isPositive;
  final int rating; // 1 to 5
  final String comment;
  final String suggestedFocus;
  final DateTime timestamp;

  const TutorFeedback({
    required this.id,
    required this.isPositive,
    this.rating = 5,
    required this.comment,
    this.suggestedFocus = '',
    required this.timestamp,
  });

  TutorFeedback copyWith({
    String? id,
    bool? isPositive,
    int? rating,
    String? comment,
    String? suggestedFocus,
    DateTime? timestamp,
  }) {
    return TutorFeedback(
      id: id ?? this.id,
      isPositive: isPositive ?? this.isPositive,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      suggestedFocus: suggestedFocus ?? this.suggestedFocus,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isPositive': isPositive,
        'rating': rating,
        'comment': comment,
        'suggestedFocus': suggestedFocus,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TutorFeedback.fromJson(Map<String, dynamic> json) => TutorFeedback(
        id: json['id'] as String,
        isPositive: json['isPositive'] as bool? ?? true,
        rating: json['rating'] as int? ?? 5,
        comment: json['comment'] as String? ?? '',
        suggestedFocus: json['suggestedFocus'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorFeedback &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isPositive == other.isPositive &&
          comment == other.comment;

  @override
  int get hashCode => Object.hash(id, isPositive, comment);
}
