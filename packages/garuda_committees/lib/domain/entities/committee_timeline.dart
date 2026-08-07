library;

import 'package:meta/meta.dart';

/// Immutable model representing key timeline milestones for a Committee.
@immutable
class CommitteeTimeline {
  final DateTime date;
  final String milestone;
  final String description;

  const CommitteeTimeline({
    required this.date,
    required this.milestone,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'milestone': milestone,
        'description': description,
      };

  factory CommitteeTimeline.fromJson(Map<String, dynamic> json) => CommitteeTimeline(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        milestone: json['milestone'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}
