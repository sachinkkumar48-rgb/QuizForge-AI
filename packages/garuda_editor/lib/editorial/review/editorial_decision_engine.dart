library;

import 'review_models.dart';

class DecisionResult {
  final bool isApproved;
  final bool isRejected;
  final bool requiresConflictResolution;
  final String summary;

  const DecisionResult({
    required this.isApproved,
    required this.isRejected,
    required this.requiresConflictResolution,
    required this.summary,
  });
}

class EditorialDecisionEngine {
  static DecisionResult evaluate({
    required List<EditorialReview> reviews,
    required ReviewerTier tier,
    ConflictResolution? conflictResolution,
  }) {
    if (reviews.isEmpty) {
      return const DecisionResult(
        isApproved: false,
        isRejected: false,
        requiresConflictResolution: false,
        summary: 'No reviews submitted yet.',
      );
    }

    if (conflictResolution != null) {
      final approved = conflictResolution.finalDecision == ReviewDecision.approve;
      return DecisionResult(
        isApproved: approved,
        isRejected: !approved,
        requiresConflictResolution: false,
        summary: 'Resolved by senior reviewer: ${conflictResolution.finalDecision.name}',
      );
    }

    switch (tier) {
      case ReviewerTier.singleReviewer:
        final last = reviews.last;
        return DecisionResult(
          isApproved: last.decision == ReviewDecision.approve,
          isRejected: last.decision == ReviewDecision.reject,
          requiresConflictResolution: false,
          summary: 'Single reviewer decision: ${last.decision.name}',
        );

      case ReviewerTier.dualReviewer:
        if (reviews.length < 2) {
          return DecisionResult(
            isApproved: false,
            isRejected: reviews.any((r) => r.decision == ReviewDecision.reject),
            requiresConflictResolution: false,
            summary: 'Awaiting second reviewer for dual review consensus.',
          );
        }
        final first = reviews[0].decision;
        final second = reviews[1].decision;

        if (first == ReviewDecision.approve && second == ReviewDecision.approve) {
          return const DecisionResult(
            isApproved: true,
            isRejected: false,
            requiresConflictResolution: false,
            summary: 'Dual reviewer unanimous approval.',
          );
        } else if (first == ReviewDecision.reject || second == ReviewDecision.reject) {
          return const DecisionResult(
            isApproved: false,
            isRejected: true,
            requiresConflictResolution: false,
            summary: 'Dual review rejected.',
          );
        } else {
          return const DecisionResult(
            isApproved: false,
            isRejected: false,
            requiresConflictResolution: true,
            summary: 'Conflict in dual review decisions. Senior resolution required.',
          );
        }

      case ReviewerTier.seniorReviewer:
      case ReviewerTier.chiefEditor:
        final hasChiefApproval = reviews.any((r) =>
            r.tier == ReviewerTier.chiefEditor && r.decision == ReviewDecision.approve);
        final hasSeniorApproval = reviews.any((r) =>
            (r.tier == ReviewerTier.seniorReviewer || r.tier == ReviewerTier.chiefEditor) &&
            r.decision == ReviewDecision.approve);

        if (tier == ReviewerTier.chiefEditor) {
          return DecisionResult(
            isApproved: hasChiefApproval,
            isRejected: reviews.any((r) => r.decision == ReviewDecision.reject),
            requiresConflictResolution: false,
            summary: hasChiefApproval ? 'Chief Editor Approved' : 'Awaiting Chief Editor Approval',
          );
        }

        return DecisionResult(
          isApproved: hasSeniorApproval,
          isRejected: reviews.any((r) => r.decision == ReviewDecision.reject),
          requiresConflictResolution: false,
          summary: hasSeniorApproval ? 'Senior Reviewer Approved' : 'Awaiting Senior Reviewer Approval',
        );
    }
  }
}
