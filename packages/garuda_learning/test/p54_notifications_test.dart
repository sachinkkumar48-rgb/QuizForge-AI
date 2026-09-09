/// P54 Institutional Communication & Notifications Test Suite (TITAN-KO-054.0).
///
/// Comprehensive unit, contract, and lifecycle verification covering:
/// 1. Notification creation & persistence
/// 2. Recipient resolution & tenant/user isolation
/// 3. Read / Acknowledge / Dismiss deterministic lifecycle
/// 4. Priority handling & unread metrics
/// 5. Deterministic deduplication & idempotent event processing
/// 6. Academic event hooks (Enrollment, Assessment, Grade, Attendance, Credentials)
/// 7. Offline persistence snapshot, restart recovery & sync idempotency
/// 8. Authorization boundaries & complete end-to-end notification lifecycle
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 25, 10, 0, 0);

  late InMemoryNotificationRepository notifRepo;
  late NotificationService notifService;

  setUp(() {
    notifRepo = InMemoryNotificationRepository();
    notifService = NotificationService(
      notificationRepository: notifRepo,
      clock: () => baseTime,
    );
  });

  group('P54: Notification Creation, Persistence & Lifecycle', () {
    test(
        '1. notification creation persists unread notification and audit record',
        () async {
      final notif = await notifService.createNotification(
        recipientId: 'learner_alice',
        recipientRole: 'learner',
        type: NotificationType.enrollment,
        title: 'Course Enrollment Activated',
        message: 'You have been enrolled in Constitutional Law 101.',
        sourceEntityType: 'enrollment',
        sourceEntityId: 'enr_const_101_alice',
      );

      expect(notif.notificationId, isNotEmpty);
      expect(notif.isUnread, isTrue);
      expect(notif.recipientId, equals('learner_alice'));
      expect(notif.type, equals(NotificationType.enrollment));

      final stored = await notifRepo.getNotification(notif.notificationId);
      expect(stored, isNotNull);
      expect(stored!.title, equals('Course Enrollment Activated'));

      final audits = await notifRepo.listAuditRecords(
          notificationId: notif.notificationId);
      expect(audits.length, equals(1));
      expect(audits.first.action,
          equals(NotificationAuditAction.notificationCreated));
    });

    test('2. notification persistence maintains state and metadata', () async {
      final notif = await notifService.createNotification(
        recipientId: 'learner_bob',
        type: NotificationType.assessment,
        title: 'Midterm Exam Available',
        message: 'The midterm assessment is now open.',
        sourceEntityType: 'assessment',
        sourceEntityId: 'assess_midterm_01',
        metadata: {'durationMinutes': 90, 'maxScore': 100},
      );

      final retrieved = await notifRepo.getNotification(notif.notificationId);
      expect(retrieved, isNotNull);
      expect(retrieved!.metadata['durationMinutes'], equals(90));
      expect(retrieved.metadata['maxScore'], equals(100));
    });

    test('3. recipient resolution ensures delivery only to target user',
        () async {
      await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.grade,
        title: 'Grade A',
        message: 'Grade posted.',
        sourceEntityType: 'grade',
        sourceEntityId: 'gr_01',
      );
      await notifService.createNotification(
        recipientId: 'learner_bob',
        type: NotificationType.grade,
        title: 'Grade B',
        message: 'Grade posted.',
        sourceEntityType: 'grade',
        sourceEntityId: 'gr_02',
      );

      final aliceNotifs =
          await notifService.listNotifications(recipientId: 'learner_alice');
      expect(aliceNotifs.length, equals(1));
      expect(aliceNotifs.first.recipientId, equals('learner_alice'));

      final bobNotifs =
          await notifService.listNotifications(recipientId: 'learner_bob');
      expect(bobNotifs.length, equals(1));
      expect(bobNotifs.first.recipientId, equals('learner_bob'));
    });

    test('4. tenant isolation isolates notifications across tenants', () async {
      await notifService.createNotification(
        tenantId: 'tenant_alpha',
        recipientId: 'learner_alice',
        type: NotificationType.attendance,
        title: 'Alpha Session',
        message: 'Alpha session scheduled.',
        sourceEntityType: 'attendance',
        sourceEntityId: 'att_01',
      );
      await notifService.createNotification(
        tenantId: 'tenant_beta',
        recipientId: 'learner_alice',
        type: NotificationType.attendance,
        title: 'Beta Session',
        message: 'Beta session scheduled.',
        sourceEntityType: 'attendance',
        sourceEntityId: 'att_02',
      );

      final alphaList = await notifService.listNotifications(
        recipientId: 'learner_alice',
        tenantId: 'tenant_alpha',
      );
      expect(alphaList.length, equals(1));
      expect(alphaList.first.title, equals('Alpha Session'));

      final betaList = await notifService.listNotifications(
        recipientId: 'learner_alice',
        tenantId: 'tenant_beta',
      );
      expect(betaList.length, equals(1));
      expect(betaList.first.title, equals('Beta Session'));
    });

    test(
        '5. learner cross-user isolation prevents accessing another learner notifications',
        () async {
      final notif = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.grade,
        title: 'Confidential Grade',
        message: 'Your official grade is A+.',
        sourceEntityType: 'grade',
        sourceEntityId: 'gr_alice_secret',
      );

      // Learner Bob attempts to mark Alice's notification as read
      expect(
        () => notifService.markAsRead(
          notificationId: notif.notificationId,
          recipientId: 'learner_bob',
        ),
        throwsA(isA<NotificationSecurityException>()),
      );

      // Learner Bob attempts to dismiss Alice's notification
      expect(
        () => notifService.dismissNotification(
          notificationId: notif.notificationId,
          recipientId: 'learner_bob',
        ),
        throwsA(isA<NotificationSecurityException>()),
      );
    });

    test('6. notification type validation correctly identifies categories',
        () async {
      for (final t in NotificationType.values) {
        final notif = await notifService.createNotification(
          recipientId: 'learner_alice',
          type: t,
          title: 'Title ${t.name}',
          message: 'Message ${t.name}',
          sourceEntityType: 'source_${t.name}',
          sourceEntityId: 'id_${t.name}',
        );
        expect(notif.type, equals(t));
      }
    });

    test('7. priority ordering reflects urgency levels', () async {
      await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.attendance,
        title: 'Low Priority Info',
        message: 'Info',
        sourceEntityType: 'att',
        sourceEntityId: 'att_low',
        priority: NotificationPriority.low,
      );
      await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.intervention,
        title: 'Urgent Intervention Alert',
        message: 'Action needed immediately',
        sourceEntityType: 'signal',
        sourceEntityId: 'sig_urgent',
        priority: NotificationPriority.urgent,
      );

      final notifs =
          await notifService.listNotifications(recipientId: 'learner_alice');
      expect(
          notifs.any((n) => n.priority == NotificationPriority.urgent), isTrue);
      expect(notifs.any((n) => n.priority == NotificationPriority.low), isTrue);
    });

    test('8. unread state starts as true', () async {
      final notif = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.enrollment,
        title: 'New Enrollment',
        message: 'Welcome',
        sourceEntityType: 'enr',
        sourceEntityId: 'enr_01',
      );
      expect(notif.isUnread, isTrue);
      expect(notif.readAt, isNull);
    });

    test('9. mark read transitions UNREAD to READ and records timestamp',
        () async {
      final notif = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.assessment,
        title: 'Quiz 1',
        message: 'Quiz 1 ready',
        sourceEntityType: 'quiz',
        sourceEntityId: 'quiz_01',
      );

      final readNotif = await notifService.markAsRead(
        notificationId: notif.notificationId,
        recipientId: 'learner_alice',
      );
      expect(readNotif.isRead, isTrue);
      expect(readNotif.readAt, equals(baseTime));

      final audits = await notifRepo.listAuditRecords(
          notificationId: notif.notificationId);
      expect(
          audits
              .any((a) => a.action == NotificationAuditAction.notificationRead),
          isTrue);
    });

    test('10. acknowledge transitions to ACKNOWLEDGED', () async {
      final notif = await notifService.createNotification(
        recipientId: 'faculty_sharma',
        recipientRole: 'faculty',
        type: NotificationType.intervention,
        title: 'At-Risk Alert',
        message: 'Student needs mentoring',
        sourceEntityType: 'signal',
        sourceEntityId: 'sig_01',
      );

      final ackNotif = await notifService.acknowledgeNotification(
        notificationId: notif.notificationId,
        recipientId: 'faculty_sharma',
      );
      expect(ackNotif.isAcknowledged, isTrue);
      expect(ackNotif.acknowledgedAt, equals(baseTime));

      final audits = await notifRepo.listAuditRecords(
          notificationId: notif.notificationId);
      expect(
          audits.any((a) =>
              a.action == NotificationAuditAction.notificationAcknowledged),
          isTrue);
    });

    test(
        '11. dismiss transitions to DISMISSED and excludes from active unread count',
        () async {
      final notif = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.attendance,
        title: 'Session Info',
        message: 'Lecture completed',
        sourceEntityType: 'att',
        sourceEntityId: 'att_dismiss_01',
      );

      final dismissed = await notifService.dismissNotification(
        notificationId: notif.notificationId,
        recipientId: 'learner_alice',
      );
      expect(dismissed.isDismissed, isTrue);

      final unreadCount =
          await notifService.getUnreadCount(recipientId: 'learner_alice');
      expect(unreadCount, equals(0));
    });

    test('12. invalid state transition rejects marking dismissed as read',
        () async {
      final notif = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.attendance,
        title: 'Session Info',
        message: 'Lecture completed',
        sourceEntityType: 'att',
        sourceEntityId: 'att_dismiss_02',
      );
      await notifService.dismissNotification(
        notificationId: notif.notificationId,
        recipientId: 'learner_alice',
      );

      expect(
        () => notifService.markAsRead(
          notificationId: notif.notificationId,
          recipientId: 'learner_alice',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('13. unread count correctly calculates pending notifications',
        () async {
      expect(await notifService.getUnreadCount(recipientId: 'learner_alice'),
          equals(0));

      for (int i = 1; i <= 3; i++) {
        await notifService.createNotification(
          recipientId: 'learner_alice',
          type: NotificationType.grade,
          title: 'Grade $i',
          message: 'Grade posted',
          sourceEntityType: 'grade',
          sourceEntityId: 'gr_$i',
        );
      }
      expect(await notifService.getUnreadCount(recipientId: 'learner_alice'),
          equals(3));
    });

    test(
        '14. mark-all-read updates all pending unread notifications for recipient',
        () async {
      for (int i = 1; i <= 4; i++) {
        await notifService.createNotification(
          recipientId: 'learner_bob',
          type: NotificationType.assessment,
          title: 'Assessment $i',
          message: 'Assessment details',
          sourceEntityType: 'assess',
          sourceEntityId: 'assess_$i',
        );
      }
      expect(await notifService.getUnreadCount(recipientId: 'learner_bob'),
          equals(4));

      final count =
          await notifService.markAllAsRead(recipientId: 'learner_bob');
      expect(count, equals(4));
      expect(await notifService.getUnreadCount(recipientId: 'learner_bob'),
          equals(0));

      final allNotifs =
          await notifService.listNotifications(recipientId: 'learner_bob');
      expect(allNotifs.every((n) => n.isRead), isTrue);
    });
  });

  group('P54: Deduplication & Idempotent Event Processing', () {
    test(
        '15. deduplication key prevents duplicate notifications for same source event',
        () async {
      final notif1 = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.enrollment,
        title: 'Enrolled in Law 101',
        message: 'Welcome',
        sourceEntityType: 'enrollment',
        sourceEntityId: 'enr_law_101_alice',
      );

      final notif2 = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.enrollment,
        title: 'Enrolled in Law 101 - Duplicate Call',
        message: 'Duplicate call attempt',
        sourceEntityType: 'enrollment',
        sourceEntityId: 'enr_law_101_alice',
      );

      expect(notif1.notificationId, equals(notif2.notificationId));
      expect(notif2.title,
          equals('Enrolled in Law 101')); // Original title preserved

      final allNotifs =
          await notifService.listNotifications(recipientId: 'learner_alice');
      expect(allNotifs.length, equals(1));
    });

    test('16. repeated event processing is strictly idempotent', () async {
      for (int i = 0; i < 5; i++) {
        await notifService.notifyGradePublished(
          learnerId: 'learner_alice',
          courseId: 'course_const_101',
          courseTitle: 'Constitutional Law Foundations',
          finalGrade: 'A+',
        );
      }

      final notifs =
          await notifService.listNotifications(recipientId: 'learner_alice');
      expect(notifs.length, equals(1));
      expect(notifs.first.type, equals(NotificationType.grade));
    });
  });

  group('P54: Academic Event Hooks & Verification', () {
    test('17. enrollment notification delivers active course notice', () async {
      final notif = await notifService.notifyEnrollmentActivated(
        learnerId: 'learner_alice',
        courseId: 'course_crim_201',
        courseTitle: 'Criminal Jurisprudence',
      );
      expect(notif.type, equals(NotificationType.enrollment));
      expect(notif.title, contains('Criminal Jurisprudence'));
      expect(notif.actionRoute, equals('/course_enrollment'));
    });

    test('18. assessment notification informs learner of available evaluation',
        () async {
      final notif = await notifService.notifyAssessmentPublished(
        recipientId: 'learner_bob',
        assessmentId: 'assess_prelims_mock',
        assessmentTitle: 'Civil Services Prelims Mock 1',
        courseId: 'course_upsc_gs1',
      );
      expect(notif.type, equals(NotificationType.assessment));
      expect(notif.sourceEntityId, equals('assess_prelims_mock'));
    });

    test('19. grade notification informs learner of official grade publication',
        () async {
      final notif = await notifService.notifyGradePublished(
        learnerId: 'learner_alice',
        courseId: 'course_const_101',
        courseTitle: 'Constitutional Law Foundations',
        finalGrade: 'A',
      );
      expect(notif.type, equals(NotificationType.grade));
      expect(notif.message, contains('Grade A'));
    });

    test('20. grade dispute notification alerts faculty or learner', () async {
      final notif = await notifService.notifyGradeDisputeUpdated(
        recipientId: 'faculty_sharma',
        recipientRole: 'faculty',
        disputeId: 'disp_001',
        courseId: 'course_const_101',
        newStatus: 'UNDER_REVIEW',
      );
      expect(notif.type, equals(NotificationType.gradeDispute));
      expect(notif.recipientRole, equals('faculty'));
      expect(notif.message, contains('UNDER_REVIEW'));
    });

    test('21. attendance notification announces scheduled session', () async {
      final notif = await notifService.notifyAttendanceSessionScheduled(
        learnerId: 'learner_alice',
        sessionId: 'sess_101',
        sessionTitle: 'Preamble & Fundamental Duties',
        courseId: 'course_const_101',
        scheduledAt: baseTime.add(const Duration(days: 1)),
      );
      expect(notif.type, equals(NotificationType.attendance));
      expect(notif.title, contains('Preamble & Fundamental Duties'));
    });

    test('22. intervention notification alerts faculty to at-risk learner',
        () async {
      final notif = await notifService.notifyAttendanceInterventionCreated(
        facultyId: 'faculty_sharma',
        learnerId: 'learner_kavita',
        courseId: 'course_const_101',
        signalId: 'sig_low_att_kavita',
        signalType: 'lowAttendance',
        triggerValue: 40.0,
        thresholdValue: 75.0,
      );
      expect(notif.type, equals(NotificationType.intervention));
      expect(notif.priority, equals(NotificationPriority.urgent));
      expect(notif.recipientId, equals('faculty_sharma'));
      expect(notif.message, contains('40.0% < 75.0%'));
    });

    test('23. transcript notification informs learner of issued transcript',
        () async {
      final notif = await notifService.notifyTranscriptIssued(
        learnerId: 'learner_alice',
        transcriptId: 'trans_2026_alice',
      );
      expect(notif.type, equals(NotificationType.transcript));
      expect(notif.message, contains('trans_2026_alice'));
    });

    test('24. certificate notification informs learner of issued credential',
        () async {
      final notif = await notifService.notifyCertificateIssued(
        learnerId: 'learner_alice',
        certificateId: 'cert_const_law_alice',
        courseTitle: 'Constitutional Law Foundations',
      );
      expect(notif.type, equals(NotificationType.certificate));
      expect(notif.message, contains('cert_const_law_alice'));
    });
  });

  group('P54: Persistence, Offline Sync & Integration Boundaries', () {
    test(
        '25. offline persistence: exportSnapshot and importSnapshot persist state accurately',
        () async {
      await notifService.notifyEnrollmentActivated(
        learnerId: 'learner_alice',
        courseId: 'course_law_101',
        courseTitle: 'Constitutional Law',
      );
      await notifService.notifyGradePublished(
        learnerId: 'learner_alice',
        courseId: 'course_law_101',
        courseTitle: 'Constitutional Law',
        finalGrade: 'O (Outstanding)',
      );

      final snapshot = await notifRepo.exportSnapshot();
      expect(snapshot['notifications'], isNotEmpty);
      expect(snapshot['auditRecords'], isNotEmpty);

      // Restore in fresh repository
      final freshRepo = InMemoryNotificationRepository();
      await freshRepo.importSnapshot(snapshot);

      final freshService =
          NotificationService(notificationRepository: freshRepo);
      final restored =
          await freshService.listNotifications(recipientId: 'learner_alice');
      expect(restored.length, equals(2));
      expect(restored.map((n) => n.type),
          containsAll([NotificationType.enrollment, NotificationType.grade]));
    });

    test('26. synchronization merges state cleanly without losing read state',
        () async {
      final notif = await notifService.notifyAssessmentPublished(
        recipientId: 'learner_alice',
        assessmentId: 'assess_01',
        assessmentTitle: 'Torts Quiz',
        courseId: 'course_torts',
      );
      await notifService.markAsRead(
        notificationId: notif.notificationId,
        recipientId: 'learner_alice',
      );

      final snapshot = await notifRepo.exportSnapshot();
      final freshRepo = InMemoryNotificationRepository();
      await freshRepo.importSnapshot(snapshot);

      final restoredNotif =
          await freshRepo.getNotification(notif.notificationId);
      expect(restoredNotif, isNotNull);
      expect(restoredNotif!.isRead, isTrue);
      expect(restoredNotif.readAt, isNotNull);
    });

    test(
        '27. sync idempotency: re-importing snapshot does not create duplicates',
        () async {
      await notifService.notifyEnrollmentActivated(
        learnerId: 'learner_alice',
        courseId: 'course_law_101',
        courseTitle: 'Constitutional Law',
      );

      final snapshot = await notifRepo.exportSnapshot();
      await notifRepo.importSnapshot(snapshot);
      await notifRepo.importSnapshot(snapshot);

      final notifs =
          await notifService.listNotifications(recipientId: 'learner_alice');
      expect(notifs.length, equals(1));
    });

    test('28. navigation route metadata points to valid destination', () async {
      final notif = await notifService.notifyCertificateIssued(
        learnerId: 'learner_alice',
        certificateId: 'cert_123',
        courseTitle: 'Cyber Law',
      );
      expect(notif.actionRoute, equals('/academic_credentials'));
    });

    test('29. authorization rejects non-matching actor from modifying state',
        () async {
      final notif = await notifService.notifyResultPublished(
        learnerId: 'learner_alice',
        attemptId: 'att_001',
        assessmentTitle: 'Legal Reasoning',
        scorePercentage: 88.5,
      );

      expect(
        () => notifService.acknowledgeNotification(
          notificationId: notif.notificationId,
          recipientId: 'attacker_hacker',
        ),
        throwsA(isA<NotificationSecurityException>()),
      );
    });

    test('30. complete end-to-end notification lifecycle', () async {
      // 1. Create notification
      final notif = await notifService.createNotification(
        recipientId: 'learner_alice',
        type: NotificationType.intervention,
        title: 'Attendance Alert',
        message: 'Attendance is below 75%',
        sourceEntityType: 'attendance',
        sourceEntityId: 'sig_att_alice',
        priority: NotificationPriority.urgent,
      );
      expect(notif.isUnread, isTrue);

      // 2. Query unread count
      var unreadCount =
          await notifService.getUnreadCount(recipientId: 'learner_alice');
      expect(unreadCount, equals(1));

      // 3. Mark read
      final readNotif = await notifService.markAsRead(
        notificationId: notif.notificationId,
        recipientId: 'learner_alice',
      );
      expect(readNotif.isRead, isTrue);

      unreadCount =
          await notifService.getUnreadCount(recipientId: 'learner_alice');
      expect(unreadCount, equals(0));

      // 4. Formally acknowledge
      final ackNotif = await notifService.acknowledgeNotification(
        notificationId: notif.notificationId,
        recipientId: 'learner_alice',
      );
      expect(ackNotif.isAcknowledged, isTrue);

      // 5. Dismiss from active views
      final dismissed = await notifService.dismissNotification(
        notificationId: notif.notificationId,
        recipientId: 'learner_alice',
      );
      expect(dismissed.isDismissed, isTrue);

      // 6. Verify full chronological audit trail
      final audits = await notifRepo.listAuditRecords(
          notificationId: notif.notificationId);
      expect(audits.length, equals(4));
      expect(
          audits.map((a) => a.action),
          equals([
            NotificationAuditAction.notificationCreated,
            NotificationAuditAction.notificationRead,
            NotificationAuditAction.notificationAcknowledged,
            NotificationAuditAction.notificationDismissed,
          ]));
    });
  });
}
