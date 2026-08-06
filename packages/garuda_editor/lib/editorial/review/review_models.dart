library;

import '../../domain/entities/editorial_role.dart';

enum ReviewerTier {
  singleReviewer,
  dualReviewer,
  seniorReviewer,
  chiefEditor,
}

enum ReviewDecision {
  approve,
  reject,
  requestChanges,
  escalate,
}

class EditorialReview {
  final String id;
  final String objectId;
  final String reviewerId;
  final String reviewerName;
  final EditorialRole reviewerRole;
  final ReviewerTier tier;
  final ReviewDecision decision;
  final String comments;
  final DateTime timestamp;
  final int round;

  const EditorialReview({
    required this.id,
    required this.objectId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerRole,
    required this.tier,
    required this.decision,
    required this.comments,
    required this.timestamp,
    this.round = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'objectId': objectId,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'reviewerRole': reviewerRole.name,
        'tier': tier.name,
        'decision': decision.name,
        'comments': comments,
        'timestamp': timestamp.toIso8601String(),
        'round': round,
      };

  factory EditorialReview.fromJson(Map<String, dynamic> json) => EditorialReview(
        id: json['id'] as String,
        objectId: json['objectId'] as String,
        reviewerId: json['reviewerId'] as String,
        reviewerName: json['reviewerName'] as String,
        reviewerRole: EditorialRole.values.firstWhere(
          (r) => r.name == json['reviewerRole'],
          orElse: () => EditorialRole.peerReviewer,
        ),
        tier: ReviewerTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => ReviewerTier.singleReviewer,
        ),
        decision: ReviewDecision.values.firstWhere(
          (d) => d.name == json['decision'],
          orElse: () => ReviewDecision.requestChanges,
        ),
        comments: json['comments'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        round: json['round'] as int? ?? 1,
      );
}

class ConflictResolution {
  final String resolvedByReviewerId;
  final ReviewDecision finalDecision;
  final String resolutionNotes;
  final DateTime resolvedAt;

  const ConflictResolution({
    required this.resolvedByReviewerId,
    required this.finalDecision,
    required this.resolutionNotes,
    required this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
        'resolvedByReviewerId': resolvedByReviewerId,
        'finalDecision': finalDecision.name,
        'resolutionNotes': resolutionNotes,
        'resolvedAt': resolvedAt.toIso8601String(),
      };

  factory ConflictResolution.fromJson(Map<String, dynamic> json) => ConflictResolution(
        resolvedByReviewerId: json['resolvedByReviewerId'] as String,
        finalDecision: ReviewDecision.values.firstWhere(
          (d) => d.name == json['finalDecision'],
          orElse: () => ReviewDecision.approve,
        ),
        resolutionNotes: json['resolutionNotes'] as String,
        resolvedAt: DateTime.parse(json['resolvedAt'] as String),
      );
}
