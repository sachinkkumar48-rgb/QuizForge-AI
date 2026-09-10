import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quizforge_upsc/core/network/api_client.dart';
import 'package:quizforge_upsc/repositories/impl/http_assessment_repository.dart';
import 'package:quizforge_upsc/repositories/impl/http_attendance_repository.dart';
import 'package:quizforge_upsc/repositories/impl/http_credential_repository.dart';
import 'package:quizforge_upsc/repositories/impl/http_enrollment_repository.dart';
import 'package:quizforge_upsc/repositories/impl/http_gradebook_repository.dart';
import 'package:quizforge_upsc/repositories/impl/http_notification_repository.dart';

void main() {
  group('HttpEnrollmentRepository Tests (P57)', () {
    test('saveCourse posts course and caches locally', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/lms/courses');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['courseId'], equals('crs-101'));
        return http.Response(jsonEncode({'success': true, 'course': body}), 200);
      });

      final repo = HttpEnrollmentRepository(apiClient: ApiClient(client: mockClient));
      final course = Course(
        courseId: 'crs-101',
        title: 'Constitutional Law',
        examId: 'clat_pg',
        facultyId: 'fac-01',
      );

      await repo.saveCourse(course);
      final fetched = await repo.getCourse('crs-101');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Constitutional Law'));
    });

    test('saveEnrollment and getActiveEnrollment', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'enrollment': {
              'enrollmentId': 'enr-101',
              'learnerId': 'lrn-01',
              'courseId': 'crs-101',
              'status': 'active',
              'enrolledBy': 'admin',
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            }
          }),
          200,
        );
      });

      final repo = HttpEnrollmentRepository(apiClient: ApiClient(client: mockClient));
      final enrollment = Enrollment(
        enrollmentId: 'enr-101',
        learnerId: 'lrn-01',
        courseId: 'crs-101',
        enrolledBy: 'admin',
      );

      await repo.saveEnrollment(enrollment);
      final active = await repo.getActiveEnrollmentForLearnerCourse(
        learnerId: 'lrn-01',
        courseId: 'crs-101',
      );
      expect(active, isNotNull);
      expect(active!.enrollmentId, equals('enr-101'));
    });

    test('offline fallback preserves course write when remote fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Network Error', 500);
      });

      final repo = HttpEnrollmentRepository(apiClient: ApiClient(client: mockClient));
      final course = Course(
        courseId: 'crs-offline-01',
        title: 'Offline Jurisprudence',
        examId: 'clat_pg',
        facultyId: 'fac-01',
      );

      await repo.saveCourse(course);
      final retrieved = await repo.getCourse('crs-offline-01');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Offline Jurisprudence'));
    });
  });

  group('HttpAssessmentRepository Tests (P57)', () {
    test('saveAssessment and getAssessmentById', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'assessment': {
              'assessmentId': 'asm-201',
              'title': 'Mock Bar Exam',
              'description': 'Comprehensive test',
              'examId': 'clat_pg',
              'creatorFacultyId': 'fac-01',
              'questionIds': ['q-1', 'q-2'],
              'marksConfig': {'marksPerQuestion': 2.0, 'negativeMarkRatio': 0.25, 'passingPercentage': 50.0},
              'timingConfig': {'durationMinutes': 60},
              'maxAttempts': 2,
              'status': 'published',
              'cohortIds': ['cohort-1'],
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            }
          }),
          200,
        );
      });

      final repo = HttpAssessmentRepository(apiClient: ApiClient(client: mockClient));
      final assessment = Assessment(
        assessmentId: 'asm-201',
        title: 'Mock Bar Exam',
        description: 'Comprehensive test',
        examId: 'clat_pg',
        creatorFacultyId: 'fac-01',
        questionIds: ['q-1', 'q-2'],
      );

      await repo.saveAssessment(assessment);
      final retrieved = await repo.getAssessmentById('asm-201');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Mock Bar Exam'));
    });

    test('saveAttempt and getResultForAttempt', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'result': {
              'resultId': 'res-101',
              'attemptId': 'att-101',
              'assessmentId': 'asm-201',
              'learnerId': 'lrn-01',
              'score': 85.0,
              'maxScore': 100.0,
              'percentage': 85.0,
              'isPassed': true,
              'evaluatedAt': DateTime.now().toUtc().toIso8601String(),
            }
          }),
          200,
        );
      });

      final repo = HttpAssessmentRepository(apiClient: ApiClient(client: mockClient));
      final result = AssessmentResult(
        resultId: 'res-101',
        attemptId: 'att-101',
        assessmentId: 'asm-201',
        learnerId: 'lrn-01',
        score: 85.0,
        maxScore: 100.0,
        percentage: 85.0,
        isPassed: true,
      );

      await repo.saveResult(result);
      final fetched = await repo.getResultForAttempt('att-101');
      expect(fetched, isNotNull);
      expect(fetched!.isPassed, isTrue);
    });
  });

  group('HttpGradebookRepository Tests (P57)', () {
    test('saveGradeEntry and listGradeEntries', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'entries': [
              {
                'entryId': 'grd-001',
                'cohortId': 'cohort-01',
                'assessmentId': 'asm-201',
                'learnerId': 'lrn-01',
                'finalScore': 90.0,
                'finalMaxScore': 100.0,
                'finalPercentage': 90.0,
                'letterGrade': 'A',
                'publicationStatus': 'published',
                'createdAt': DateTime.now().toUtc().toIso8601String(),
                'updatedAt': DateTime.now().toUtc().toIso8601String(),
              }
            ]
          }),
          200,
        );
      });

      final repo = HttpGradebookRepository(apiClient: ApiClient(client: mockClient));
      final entry = GradebookEntry(
        entryId: 'grd-001',
        cohortId: 'cohort-01',
        assessmentId: 'asm-201',
        learnerId: 'lrn-01',
        finalScore: 90.0,
        finalMaxScore: 100.0,
        finalPercentage: 90.0,
        letterGrade: 'A',
        publicationStatus: GradePublicationStatus.published,
      );

      await repo.saveGradeEntry(entry);
      final entries = await repo.listGradeEntries(learnerId: 'lrn-01');
      expect(entries, isNotEmpty);
      expect(entries.first.letterGrade, equals('A'));
    });
  });

  group('HttpAttendanceRepository Tests (P57)', () {
    test('saveSession and listAttendanceForSession', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'records': [
              {
                'attendanceId': 'att-rec-01',
                'sessionId': 'sess-01',
                'courseId': 'crs-101',
                'learnerId': 'lrn-01',
                'sessionDate': DateTime.now().toUtc().toIso8601String(),
                'status': 'present',
                'recordedBy': 'faculty',
                'recordedAt': DateTime.now().toUtc().toIso8601String(),
              }
            ]
          }),
          200,
        );
      });

      final repo = HttpAttendanceRepository(apiClient: ApiClient(client: mockClient));
      final session = AttendanceSession(
        sessionId: 'sess-01',
        courseId: 'crs-101',
        title: 'Lecture 1',
        facultyId: 'fac-01',
        scheduledAt: DateTime.now().toUtc(),
      );

      await repo.saveSession(session);
      final records = await repo.listAttendanceForSession(sessionId: 'sess-01');
      expect(records, isNotEmpty);
      expect(records.first.status, equals(AttendanceStatus.present));
    });
  });

  group('HttpCredentialRepository Tests (P57)', () {
    test('saveCertificate and getCertificateByCredentialId', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'certificate': {
              'certificateId': 'cert-001',
              'credentialId': 'cred-001',
              'learnerId': 'lrn-01',
              'cohortId': 'cohort-01',
              'programName': 'Mastery of Constitutional Law',
              'issuedByFacultyId': 'fac-01',
              'issuedAt': DateTime.now().toUtc().toIso8601String(),
              'fingerprint': 'abc123sha256',
              'status': 'issued',
            }
          }),
          200,
        );
      });

      final repo = HttpCredentialRepository(apiClient: ApiClient(client: mockClient));
      final cert = CompletionCertificate(
        certificateId: 'cert-001',
        credentialId: 'cred-001',
        learnerId: 'lrn-01',
        cohortId: 'cohort-01',
        programName: 'Mastery of Constitutional Law',
        issuedByFacultyId: 'fac-01',
        fingerprint: 'abc123sha256',
      );

      await repo.saveCertificate(cert);
      final fetched = await repo.getCertificateByCredentialId('cred-001');
      expect(fetched, isNotNull);
      expect(fetched!.programName, equals('Mastery of Constitutional Law'));
    });
  });

  group('HttpNotificationRepository Tests (P57)', () {
    test('saveNotification and countUnread', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(
          jsonEncode({'recipientId': 'lrn-01', 'unreadCount': 3}),
          200,
        );
      });

      final repo = HttpNotificationRepository(apiClient: ApiClient(client: mockClient));
      final notif = LmsNotification(
        notificationId: 'notif-01',
        recipientId: 'lrn-01',
        type: NotificationType.assessment,
        title: 'New Assessment',
        message: 'Assessment is now open',
        sourceEntityType: 'assessment',
        sourceEntityId: 'asm-201',
      );

      await repo.saveNotification(notif);
      final count = await repo.countUnread(recipientId: 'lrn-01');
      expect(count, equals(3));
    });
  });
}
