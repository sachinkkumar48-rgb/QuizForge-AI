library;

import '../../domain/entities/editorial_role.dart';
import 'review_models.dart';

class EditorialReviewService {
  final Map<String, List<EditorialReview>> _reviewsByObject = {};
  final Map<String, List<ConflictResolution>> _resolutionsByObject = {};

  EditorialReview submitReview({
    required String objectId,
    required String reviewerId,
    required String reviewerName,
    required EditorialRole reviewerRole,
    required ReviewerTier tier,
    required ReviewDecision decision,
    required String comments,
    int round = 1,
  }) {
    final review = EditorialReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}_$reviewerId',
      objectId: objectId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerRole: reviewerRole,
      tier: tier,
      decision: decision,
      comments: comments,
      timestamp: DateTime.now(),
      round: round,
    );

    _reviewsByObject.putIfAbsent(objectId, () => []).add(review);
    return review;
  }

  List<EditorialReview> getReviews(String objectId) {
    return List.unmodifiable(_reviewsByObject[objectId] ?? []);
  }

  List<EditorialReview> getReviewsForRound(String objectId, int round) {
    return (getReviews(objectId)).where((r) => r.round == round).toList();
  }

  ConflictResolution recordConflictResolution({
    required String objectId,
    required String resolvedByReviewerId,
    required ReviewDecision finalDecision,
    required String resolutionNotes,
  }) {
    final resolution = ConflictResolution(
      resolvedByReviewerId: resolvedByReviewerId,
      finalDecision: finalDecision,
      resolutionNotes: resolutionNotes,
      resolvedAt: DateTime.now(),
    );

    _resolutionsByObject.putIfAbsent(objectId, () => []).add(resolution);
    return resolution;
  }

  List<ConflictResolution> getConflictResolutions(String objectId) {
    return List.unmodifiable(_resolutionsByObject[objectId] ?? []);
  }
}
