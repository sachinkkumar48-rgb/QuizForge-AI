import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('Editorial Review & Decision Engine Tests', () {
    late EditorialReviewService reviewService;
    late EditorialAssignmentService assignmentService;

    setUp(() {
      reviewService = EditorialReviewService();
      assignmentService = EditorialAssignmentService();
    });

    test('EditorialAssignmentService assigns reviewer and tracks workload', () {
      final assign = assignmentService.assignReviewer(
        objectId: 'ko_1001',
        reviewerId: 'rev_1',
        reviewerName: 'Bob Reviewer',
        reviewerRole: EditorialRole.peerReviewer,
      );

      expect(assign.reviewerId, equals('rev_1'));
      expect(assignmentService.getReviewerWorkloads()['rev_1'], equals(1));

      assignmentService.completeAssignment('ko_1001', 'rev_1');
      expect(assignmentService.getReviewerWorkloads()['rev_1'], equals(0));
    });

    test('EditorialDecisionEngine evaluates single reviewer approval', () {
      final review = reviewService.submitReview(
        objectId: 'ko_1001',
        reviewerId: 'rev_1',
        reviewerName: 'Bob Reviewer',
        reviewerRole: EditorialRole.peerReviewer,
        tier: ReviewerTier.singleReviewer,
        decision: ReviewDecision.approve,
        comments: 'Verified text accuracy.',
      );

      final decision = EditorialDecisionEngine.evaluate(
        reviews: [review],
        tier: ReviewerTier.singleReviewer,
      );

      expect(decision.isApproved, isTrue);
      expect(decision.isRejected, isFalse);
    });

    test('EditorialDecisionEngine detects conflict in dual reviewer decision', () {
      final rev1 = reviewService.submitReview(
        objectId: 'ko_1001',
        reviewerId: 'rev_1',
        reviewerName: 'Bob',
        reviewerRole: EditorialRole.peerReviewer,
        tier: ReviewerTier.dualReviewer,
        decision: ReviewDecision.approve,
        comments: 'Looks good.',
      );

      final rev2 = reviewService.submitReview(
        objectId: 'ko_1001',
        reviewerId: 'rev_2',
        reviewerName: 'Charlie',
        reviewerRole: EditorialRole.peerReviewer,
        tier: ReviewerTier.dualReviewer,
        decision: ReviewDecision.requestChanges,
        comments: 'Needs better citation.',
      );

      final decision = EditorialDecisionEngine.evaluate(
        reviews: [rev1, rev2],
        tier: ReviewerTier.dualReviewer,
      );

      expect(decision.isApproved, isFalse);
      expect(decision.requiresConflictResolution, isTrue);

      final resolution = reviewService.recordConflictResolution(
        objectId: 'ko_1001',
        resolvedByReviewerId: 'senior_1',
        finalDecision: ReviewDecision.approve,
        resolutionNotes: 'Source verified from PIB official release.',
      );

      final resolvedDecision = EditorialDecisionEngine.evaluate(
        reviews: [rev1, rev2],
        tier: ReviewerTier.dualReviewer,
        conflictResolution: resolution,
      );

      expect(resolvedDecision.isApproved, isTrue);
    });
  });
}
