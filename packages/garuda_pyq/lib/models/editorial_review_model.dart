import 'package:meta/meta.dart';

@immutable
class EditorialReview {
  final String reviewerId;
  final String status;
  final String comments;
  final DateTime timestamp;
  final Map<String, bool> checklist;

  const EditorialReview({
    required this.reviewerId,
    required this.status,
    required this.comments,
    required this.timestamp,
    this.checklist = const {},
  });

  Map<String, dynamic> toJson() => {
        'reviewerId': reviewerId,
        'status': status,
        'comments': comments,
        'timestamp': timestamp.toIso8601String(),
        'checklist': checklist,
      };

  factory EditorialReview.fromJson(Map<String, dynamic> json) => EditorialReview(
        reviewerId: json['reviewerId'] as String,
        status: json['status'] as String,
        comments: json['comments'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        checklist: Map<String, bool>.from(json['checklist'] ?? {}),
      );
}
