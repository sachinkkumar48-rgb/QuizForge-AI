library;

import 'package:meta/meta.dart';

/// Immutable timeline milestone for a Government Scheme.
@immutable
class SchemeTimeline {
  final DateTime date;
  final String milestone;
  final String description;

  const SchemeTimeline({
    required this.date,
    required this.milestone,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'milestone': milestone,
        'description': description,
      };

  factory SchemeTimeline.fromJson(Map<String, dynamic> json) => SchemeTimeline(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        milestone: json['milestone'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}
