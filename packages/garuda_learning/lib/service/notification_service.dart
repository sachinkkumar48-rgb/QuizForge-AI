/// Institutional Notification & Communication Service (TITAN-KO-054.0 P54).
///
/// Authoritative communication orchestration layer delivering academic event notifications,
/// enforcing recipient resolution, deduplication, unread counting, state transitions,
/// and immutable audit recording.
library;

import '../domain/entities/lms_notification.dart';
import '../domain/entities/notification_audit_record.dart';
import '../repository/notification_repository.dart';

class NotificationService {
  static int _auditCounter = 0;
  static int _notifCounter = 0;

  final NotificationRepository notificationRepository;
  final DateTime Function() _clock;

  NotificationService({
    required this.notificationRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  // ---------------------------------------------------------------------------
  // 1. Core Notification Dispatch & Deduplication
  // ---------------------------------------------------------------------------

  /// Creates and delivers a notification to a recipient's inbox.
  ///
  /// Guarantees idempotency via deterministic deduplication:
  /// If a notification already exists for this tenant, recipient, type, and source entity,
  /// the existing notification is returned without creating duplicates.
  Future<LmsNotification> createNotification({
    String? notificationId,
    String tenantId = 'default_tenant',
    required String recipientId,
    String recipientRole = 'learner',
    String? actorId,
    required NotificationType type,
    required String title,
    required String message,
    required String sourceEntityType,
    required String sourceEntityId,
    NotificationPriority priority = NotificationPriority.normal,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanTenantId = tenantId.trim();
    final cleanRecipientId = recipientId.trim();
    final cleanSourceType = sourceEntityType.trim();
    final cleanSourceId = sourceEntityId.trim();

    final dedupKey = LmsNotification.computeDeduplicationKey(
      tenantId: cleanTenantId,
      recipientId: cleanRecipientId,
      type: type,
      sourceEntityType: cleanSourceType,
      sourceEntityId: cleanSourceId,
    );

    // Check for existing notification (Idempotency / Deduplication)
    final existing = await notificationRepository.getNotificationByDedupKey(
      dedupKey,
      tenantId: cleanTenantId,
    );
    if (existing != null) {
      return existing;
    }

    final now = _clock();
    final id = notificationId?.trim() ??
        'notif_${type.name}_${cleanRecipientId}_${now.millisecondsSinceEpoch}_${++_notifCounter}';

    final notification = LmsNotification(
      notificationId: id,
      tenantId: cleanTenantId,
      recipientId: cleanRecipientId,
      recipientRole: recipientRole.trim(),
      actorId: actorId?.trim(),
      type: type,
      title: title.trim(),
      message: message.trim(),
      sourceEntityType: cleanSourceType,
      sourceEntityId: cleanSourceId,
      deduplicationKey: dedupKey,
      priority: priority,
      status: NotificationStatus.unread,
      createdAt: now,
      actionRoute: actionRoute?.trim(),
      metadata: metadata,
    );

    await notificationRepository.saveNotification(notification);

    // Audit log
    await notificationRepository.saveAuditRecord(
      NotificationAuditRecord(
        auditId:
            'audit_notif_created_${now.millisecondsSinceEpoch}_${++_auditCounter}',
        tenantId: cleanTenantId,
        action: NotificationAuditAction.notificationCreated,
        notificationId: id,
        recipientId: cleanRecipientId,
        actorId: actorId?.trim() ?? 'system',
        sourceEventType: cleanSourceType,
        sourceEntityId: cleanSourceId,
        details: 'Notification created: ${notification.title}',
        timestamp: now,
      ),
    );

    return notification;
  }

  // ---------------------------------------------------------------------------
  // 2. Read / Acknowledge / Dismiss Lifecycle
  // ---------------------------------------------------------------------------

  /// Marks a specific notification as READ.
  ///
  /// Strictly verifies that the caller matches the recipient (learner/cross-user isolation).
  Future<LmsNotification> markAsRead({
    required String notificationId,
    required String recipientId,
    String? tenantId,
  }) async {
    final cleanId = notificationId.trim();
    final cleanRecipient = recipientId.trim();

    final notif = await notificationRepository.getNotification(cleanId,
        tenantId: tenantId);
    if (notif == null) {
      throw NotificationNotFoundException('Notification not found: $cleanId');
    }

    // Authorization & recipient boundary check
    if (notif.recipientId != cleanRecipient) {
      throw NotificationSecurityException(
        'Unauthorized: Recipient $cleanRecipient cannot access notification owned by ${notif.recipientId}',
      );
    }

    if (notif.isRead || notif.isAcknowledged) {
      return notif; // Idempotent
    }

    final now = _clock();
    final updated = notif.markRead(at: now);
    await notificationRepository.saveNotification(updated);

    await notificationRepository.saveAuditRecord(
      NotificationAuditRecord(
        auditId:
            'audit_notif_read_${now.millisecondsSinceEpoch}_${++_auditCounter}',
        tenantId: updated.tenantId,
        action: NotificationAuditAction.notificationRead,
        notificationId: updated.notificationId,
        recipientId: cleanRecipient,
        actorId: cleanRecipient,
        sourceEventType: updated.sourceEntityType,
        sourceEntityId: updated.sourceEntityId,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Marks all unread notifications for a recipient as READ.
  Future<int> markAllAsRead({
    required String recipientId,
    String? tenantId,
  }) async {
    final cleanRecipient = recipientId.trim();
    final unreadNotifs = await notificationRepository.listNotifications(
      recipientId: cleanRecipient,
      tenantId: tenantId,
      status: NotificationStatus.unread,
    );

    if (unreadNotifs.isEmpty) return 0;

    final now = _clock();
    for (final notif in unreadNotifs) {
      final updated = notif.markRead(at: now);
      await notificationRepository.saveNotification(updated);
    }

    await notificationRepository.saveAuditRecord(
      NotificationAuditRecord(
        auditId:
            'audit_notif_all_read_${now.millisecondsSinceEpoch}_${++_auditCounter}',
        tenantId: tenantId ?? unreadNotifs.first.tenantId,
        action: NotificationAuditAction.notificationAllRead,
        recipientId: cleanRecipient,
        actorId: cleanRecipient,
        details: 'Marked ${unreadNotifs.length} notifications as read.',
        timestamp: now,
      ),
    );

    return unreadNotifs.length;
  }

  /// Formally acknowledges a notification requiring recipient confirmation.
  Future<LmsNotification> acknowledgeNotification({
    required String notificationId,
    required String recipientId,
    String? tenantId,
  }) async {
    final cleanId = notificationId.trim();
    final cleanRecipient = recipientId.trim();

    final notif = await notificationRepository.getNotification(cleanId,
        tenantId: tenantId);
    if (notif == null) {
      throw NotificationNotFoundException('Notification not found: $cleanId');
    }

    if (notif.recipientId != cleanRecipient) {
      throw NotificationSecurityException(
        'Unauthorized: Recipient $cleanRecipient cannot acknowledge notification owned by ${notif.recipientId}',
      );
    }

    if (notif.isAcknowledged) {
      return notif; // Idempotent
    }

    final now = _clock();
    final updated = notif.acknowledge(at: now);
    await notificationRepository.saveNotification(updated);

    await notificationRepository.saveAuditRecord(
      NotificationAuditRecord(
        auditId:
            'audit_notif_ack_${now.millisecondsSinceEpoch}_${++_auditCounter}',
        tenantId: updated.tenantId,
        action: NotificationAuditAction.notificationAcknowledged,
        notificationId: updated.notificationId,
        recipientId: cleanRecipient,
        actorId: cleanRecipient,
        sourceEventType: updated.sourceEntityType,
        sourceEntityId: updated.sourceEntityId,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Dismisses / archives a notification from active inbox.
  Future<LmsNotification> dismissNotification({
    required String notificationId,
    required String recipientId,
    String? tenantId,
  }) async {
    final cleanId = notificationId.trim();
    final cleanRecipient = recipientId.trim();

    final notif = await notificationRepository.getNotification(cleanId,
        tenantId: tenantId);
    if (notif == null) {
      throw NotificationNotFoundException('Notification not found: $cleanId');
    }

    if (notif.recipientId != cleanRecipient) {
      throw NotificationSecurityException(
        'Unauthorized: Recipient $cleanRecipient cannot dismiss notification owned by ${notif.recipientId}',
      );
    }

    if (notif.isDismissed) {
      return notif; // Idempotent
    }

    final now = _clock();
    final updated = notif.dismiss(at: now);
    await notificationRepository.saveNotification(updated);

    await notificationRepository.saveAuditRecord(
      NotificationAuditRecord(
        auditId:
            'audit_notif_dismiss_${now.millisecondsSinceEpoch}_${++_auditCounter}',
        tenantId: updated.tenantId,
        action: NotificationAuditAction.notificationDismissed,
        notificationId: updated.notificationId,
        recipientId: cleanRecipient,
        actorId: cleanRecipient,
        sourceEventType: updated.sourceEntityType,
        sourceEntityId: updated.sourceEntityId,
        timestamp: now,
      ),
    );

    return updated;
  }

  // ---------------------------------------------------------------------------
  // 3. Querying & Unread Metrics
  // ---------------------------------------------------------------------------

  /// Returns total count of unread notifications for a recipient.
  Future<int> getUnreadCount({
    required String recipientId,
    String? tenantId,
  }) {
    return notificationRepository.countUnread(
      recipientId: recipientId.trim(),
      tenantId: tenantId,
    );
  }

  /// Lists notifications for a recipient, supporting optional category filtering.
  Future<List<LmsNotification>> listNotifications({
    required String recipientId,
    String? tenantId,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
    String? category,
    int? limit,
  }) async {
    final cleanRecipient = recipientId.trim();

    // Map high-level category tabs to underlying NotificationTypes
    NotificationType? effectiveType = type;
    NotificationStatus? effectiveStatus = status;

    if (category != null) {
      switch (category.toLowerCase().trim()) {
        case 'unread':
          effectiveStatus = NotificationStatus.unread;
          break;
        case 'assessments':
          effectiveType = NotificationType.assessment;
          break;
        case 'grades':
          effectiveType = NotificationType.grade;
          break;
        case 'attendance':
          effectiveType = NotificationType.attendance;
          break;
        case 'monitoring':
        case 'intervention':
          effectiveType = NotificationType.intervention;
          break;
        case 'credentials':
          effectiveType = NotificationType.certificate;
          break;
        case 'all':
        default:
          break;
      }
    }

    return notificationRepository.listNotifications(
      recipientId: cleanRecipient,
      tenantId: tenantId,
      type: effectiveType,
      status: effectiveStatus,
      priority: priority,
      limit: limit,
    );
  }

  /// Retrieves chronological notification history for audit or inspection.
  Future<List<LmsNotification>> getNotificationHistory({
    required String recipientId,
    String? tenantId,
  }) {
    return notificationRepository.listNotifications(
      recipientId: recipientId.trim(),
      tenantId: tenantId,
    );
  }

  /// Retrieves immutable audit records for the notification subsystem.
  Future<List<NotificationAuditRecord>> listAuditRecords({
    String? tenantId,
    String? recipientId,
    String? notificationId,
  }) {
    return notificationRepository.listAuditRecords(
      tenantId: tenantId,
      recipientId: recipientId,
      notificationId: notificationId,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Academic Event Hooks & Bridges
  // ---------------------------------------------------------------------------

  /// Dispatches notification when a learner enrollment is confirmed / activated (P52).
  Future<LmsNotification> notifyEnrollmentActivated({
    String tenantId = 'default_tenant',
    required String learnerId,
    required String courseId,
    required String courseTitle,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: learnerId,
      recipientRole: 'learner',
      actorId: actorId,
      type: NotificationType.enrollment,
      title: 'Enrollment Confirmed: $courseTitle',
      message:
          'You have been successfully enrolled in $courseTitle ($courseId). You now have full access to learning paths.',
      sourceEntityType: 'enrollment',
      sourceEntityId: '${courseId}_$learnerId',
      priority: NotificationPriority.high,
      actionRoute: '/course_enrollment',
    );
  }

  /// Dispatches notification when an assessment is published / opened (P49).
  Future<LmsNotification> notifyAssessmentPublished({
    String tenantId = 'default_tenant',
    required String recipientId,
    String recipientRole = 'learner',
    required String assessmentId,
    required String assessmentTitle,
    required String courseId,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: recipientId,
      recipientRole: recipientRole,
      actorId: actorId,
      type: NotificationType.assessment,
      title: 'Assessment Available: $assessmentTitle',
      message:
          'A new assessment "$assessmentTitle" has been published for course $courseId.',
      sourceEntityType: 'assessment',
      sourceEntityId: assessmentId,
      priority: NotificationPriority.normal,
      actionRoute: '/assessment',
    );
  }

  /// Dispatches notification when an attempt result is computed (P49).
  Future<LmsNotification> notifyResultPublished({
    String tenantId = 'default_tenant',
    required String learnerId,
    required String attemptId,
    required String assessmentTitle,
    required double scorePercentage,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: learnerId,
      recipientRole: 'learner',
      actorId: actorId,
      type: NotificationType.result,
      title: 'Result Available: $assessmentTitle',
      message:
          'Your result for "$assessmentTitle" has been evaluated: ${scorePercentage.toStringAsFixed(1)}%.',
      sourceEntityType: 'result',
      sourceEntityId: attemptId,
      priority: NotificationPriority.normal,
      actionRoute: '/assessment_result',
    );
  }

  /// Dispatches notification when official grades are published in Gradebook (P50).
  Future<LmsNotification> notifyGradePublished({
    String tenantId = 'default_tenant',
    required String learnerId,
    required String courseId,
    required String courseTitle,
    required String finalGrade,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: learnerId,
      recipientRole: 'learner',
      actorId: actorId,
      type: NotificationType.grade,
      title: 'Official Grade Published: $courseTitle',
      message:
          'Your official grade for $courseTitle has been published: Grade $finalGrade.',
      sourceEntityType: 'gradebook',
      sourceEntityId: '${courseId}_$learnerId',
      priority: NotificationPriority.high,
      actionRoute: '/gradebook',
    );
  }

  /// Dispatches notification when a grade dispute status updates (P50).
  Future<LmsNotification> notifyGradeDisputeUpdated({
    String tenantId = 'default_tenant',
    required String recipientId,
    required String recipientRole,
    required String disputeId,
    required String courseId,
    required String newStatus,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: recipientId,
      recipientRole: recipientRole,
      actorId: actorId,
      type: NotificationType.gradeDispute,
      title: 'Grade Dispute Update: $disputeId',
      message:
          'The dispute for course $courseId has transitioned to $newStatus.',
      sourceEntityType: 'dispute',
      sourceEntityId: disputeId,
      priority: NotificationPriority.high,
      actionRoute: '/gradebook_disputes',
    );
  }

  /// Dispatches notification when an attendance session is scheduled or opened (P53).
  Future<LmsNotification> notifyAttendanceSessionScheduled({
    String tenantId = 'default_tenant',
    required String learnerId,
    required String sessionId,
    required String sessionTitle,
    required String courseId,
    required DateTime scheduledAt,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: learnerId,
      recipientRole: 'learner',
      actorId: actorId,
      type: NotificationType.attendance,
      title: 'Class Session Scheduled: $sessionTitle',
      message:
          'Session "$sessionTitle" for course $courseId is scheduled at ${scheduledAt.toLocal().toString().split('.').first}.',
      sourceEntityType: 'attendance_session',
      sourceEntityId: sessionId,
      priority: NotificationPriority.normal,
      actionRoute: '/attendance',
    );
  }

  /// Dispatches notification when an academic intervention signal is raised for faculty review (P53).
  Future<LmsNotification> notifyAttendanceInterventionCreated({
    String tenantId = 'default_tenant',
    required String facultyId,
    required String learnerId,
    required String courseId,
    required String signalId,
    required String signalType,
    required double triggerValue,
    required double thresholdValue,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: facultyId,
      recipientRole: 'faculty',
      actorId: 'system',
      type: NotificationType.intervention,
      title: 'Academic Alert: $learnerId ($courseId)',
      message:
          'Learner $learnerId triggered $signalType advisory ($triggerValue% < $thresholdValue%). Timely counseling recommended.',
      sourceEntityType: 'intervention_signal',
      sourceEntityId: signalId,
      priority: NotificationPriority.urgent,
      actionRoute: '/attendance_monitoring',
    );
  }

  /// Dispatches notification when a learner achieves full course completion (P51/P52).
  Future<LmsNotification> notifyCourseCompleted({
    String tenantId = 'default_tenant',
    required String learnerId,
    required String courseId,
    required String courseTitle,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: learnerId,
      recipientRole: 'learner',
      actorId: actorId,
      type: NotificationType.completion,
      title: 'Congratulations! Course Completed: $courseTitle',
      message:
          'You have satisfied all academic requirements for $courseTitle ($courseId).',
      sourceEntityType: 'course_completion',
      sourceEntityId: '${courseId}_$learnerId',
      priority: NotificationPriority.high,
      actionRoute: '/academic_credentials',
    );
  }

  /// Dispatches notification when an official academic transcript is issued (P51).
  Future<LmsNotification> notifyTranscriptIssued({
    String tenantId = 'default_tenant',
    required String learnerId,
    required String transcriptId,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: learnerId,
      recipientRole: 'learner',
      actorId: actorId,
      type: NotificationType.transcript,
      title: 'Official Transcript Issued',
      message:
          'Your verified academic transcript (ID: $transcriptId) has been generated and sealed.',
      sourceEntityType: 'academic_transcript',
      sourceEntityId: transcriptId,
      priority: NotificationPriority.high,
      actionRoute: '/academic_credentials',
    );
  }

  /// Dispatches notification when a course completion certificate is issued (P51).
  Future<LmsNotification> notifyCertificateIssued({
    String tenantId = 'default_tenant',
    required String learnerId,
    required String certificateId,
    required String courseTitle,
    String? actorId,
  }) {
    return createNotification(
      tenantId: tenantId,
      recipientId: learnerId,
      recipientRole: 'learner',
      actorId: actorId,
      type: NotificationType.certificate,
      title: 'Certificate Issued: $courseTitle',
      message:
          'Your official certificate of completion for $courseTitle (Certificate ID: $certificateId) has been issued.',
      sourceEntityType: 'course_completion_certificate',
      sourceEntityId: certificateId,
      priority: NotificationPriority.high,
      actionRoute: '/academic_credentials',
    );
  }
}
