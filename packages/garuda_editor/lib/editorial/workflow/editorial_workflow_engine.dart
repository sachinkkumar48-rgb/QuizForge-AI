library;

import '../../domain/entities/editorial_role.dart';
import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';
import '../dashboard/editorial_metrics_engine.dart';
import '../history/editorial_audit_trail.dart';
import '../history/rollback_service.dart';

import '../notifications/editorial_notification_service.dart';
import '../publication/publication_service.dart';
import '../quality/quality_score_engine.dart';

import '../review/editorial_assignment_service.dart';
import '../review/editorial_decision_engine.dart';
import '../review/editorial_review_service.dart';
import '../review/review_models.dart';
import '../verification/quality_gates.dart';
import 'editorial_queue.dart';
import 'editorial_state_machine.dart';

class TransitionResult {
  final KnowledgeObject updatedObject;
  final bool isSuccess;
  final String message;

  const TransitionResult({
    required this.updatedObject,
    required this.isSuccess,
    required this.message,
  });
}

class EditorialWorkflowEngine {
  final EditorialQueue queue = EditorialQueue();
  final EditorialAssignmentService assignmentService = EditorialAssignmentService();
  final EditorialReviewService reviewService = EditorialReviewService();
  final EditorialAuditTrail auditTrail = EditorialAuditTrail();
  final EditorialNotificationService notificationService = EditorialNotificationService();
  late final RollbackService rollbackService;
  late final PublicationService publicationService;

  final Map<String, KnowledgeObject> _repository = {};

  EditorialWorkflowEngine() {
    rollbackService = RollbackService(auditTrail: auditTrail);
    publicationService = PublicationService(
      auditTrail: auditTrail,
      rollbackService: rollbackService,
    );
  }

  void registerKnowledgeObject(KnowledgeObject object, {int priority = 3}) {
    _repository[object.id] = object;
    queue.enqueue(object, priority: priority);
    auditTrail.record(
      objectId: object.id,
      actorId: 'system',
      actorName: 'System Ingestion',
      actionType: AuditActionType.statusChange,
      summary: 'Registered Knowledge Object in status ${object.status.displayName}',
    );
  }

  KnowledgeObject? getKnowledgeObject(String id) => _repository[id];

  List<KnowledgeObject> get allObjects => List.unmodifiable(_repository.values.toList());

  TransitionResult advanceStage({
    required String objectId,
    required String actorId,
    required String actorName,
    String? comments,
  }) {
    final current = _repository[objectId];
    if (current == null) {
      throw ArgumentError('Knowledge Object with ID "$objectId" not found.');
    }

    final target = EditorialStateMachine.getNextSequentialStage(current.status);
    if (target == null) {
      return TransitionResult(
        updatedObject: current,
        isSuccess: false,
        message: 'Object is at terminal or non-advanceable stage (${current.status.displayName}).',
      );
    }

    return transitionStatus(
      objectId: objectId,
      targetStatus: target,
      actorId: actorId,
      actorName: actorName,
      comments: comments,
    );
  }

  TransitionResult transitionStatus({
    required String objectId,
    required EditorialStatus targetStatus,
    required String actorId,
    required String actorName,
    String? comments,
  }) {
    final current = _repository[objectId];
    if (current == null) {
      throw ArgumentError('Knowledge Object with ID "$objectId" not found.');
    }

    if (!EditorialStateMachine.canTransition(current.status, targetStatus)) {
      return TransitionResult(
        updatedObject: current,
        isSuccess: false,
        message: 'Invalid state transition from ${current.status.displayName} to ${targetStatus.displayName}.',
      );
    }

    // Enforce publication quality gates when transitioning to published
    if (targetStatus == EditorialStatus.published) {
      final gateResult = QualityGates.validatePublicationGate(current);
      if (!gateResult.isPassed) {
        return TransitionResult(
          updatedObject: current,
          isSuccess: false,
          message: gateResult.blockingReasons.join('; '),
        );
      }
    }

    final updated = current.copyWith(
      status: targetStatus,
      version: current.version + 1,
      updatedAt: DateTime.now(),
    );

    _repository[objectId] = updated;

    // Update Queue
    if (targetStatus == EditorialStatus.published || targetStatus == EditorialStatus.archived) {
      queue.dequeue(objectId);
    } else {
      queue.enqueue(updated);
    }

    // Audit Log
    auditTrail.record(
      objectId: objectId,
      actorId: actorId,
      actorName: actorName,
      actionType: AuditActionType.statusChange,
      summary: 'Status changed from ${current.status.displayName} to ${targetStatus.displayName}',
      comments: comments,
    );

    // Notifications
    if (targetStatus == EditorialStatus.published) {
      notificationService.notify(
        type: NotificationEventType.publicationCompleted,
        objectId: objectId,
        recipientId: actorId,
        title: 'Publication Completed',
        message: 'Knowledge Object "${current.title}" was published to GARUDA production corpus.',
      );
    } else if (targetStatus == EditorialStatus.rejected) {
      notificationService.notify(
        type: NotificationEventType.rejectedObject,
        objectId: objectId,
        recipientId: actorId,
        title: 'Object Rejected',
        message: 'Knowledge Object "${current.title}" was rejected during review.',
      );
    }

    return TransitionResult(
      updatedObject: updated,
      isSuccess: true,
      message: 'Successfully transitioned status to ${targetStatus.displayName}.',
    );
  }

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
    final review = reviewService.submitReview(
      objectId: objectId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerRole: reviewerRole,
      tier: tier,
      decision: decision,
      comments: comments,
      round: round,
    );

    assignmentService.completeAssignment(objectId, reviewerId);

    auditTrail.record(
      objectId: objectId,
      actorId: reviewerId,
      actorName: reviewerName,
      actionType: AuditActionType.reviewSubmitted,
      summary: 'Submitted review decision: ${decision.name} (${tier.name})',
      comments: comments,
    );

    notificationService.notify(
      type: NotificationEventType.reviewCompleted,
      objectId: objectId,
      recipientId: reviewerId,
      title: 'Review Completed',
      message: 'Review for object $objectId recorded with decision ${decision.name}.',
    );

    // Auto-advance if approved by single or senior reviewer
    final reviews = reviewService.getReviews(objectId);
    final evalResult = EditorialDecisionEngine.evaluate(reviews: reviews, tier: tier);
    if (evalResult.isApproved) {
      advanceStage(objectId: objectId, actorId: reviewerId, actorName: reviewerName);
    } else if (evalResult.isRejected) {
      transitionStatus(
        objectId: objectId,
        targetStatus: EditorialStatus.rejected,
        actorId: reviewerId,
        actorName: reviewerName,
        comments: comments,
      );
    }

    return review;
  }

  EditorialDashboardMetrics getDashboardMetrics() {
    return EditorialMetricsEngine.calculateMetrics(
      objects: allObjects,
      reviewerWorkloads: assignmentService.getReviewerWorkloads(),
      reviewService: reviewService,
    );
  }

  QualityScoreBreakdown calculateQualityScore(String objectId) {
    final obj = _repository[objectId];
    if (obj == null) throw ArgumentError('Object $objectId not found');
    return QualityScoreEngine.calculateScore(obj);
  }
}
