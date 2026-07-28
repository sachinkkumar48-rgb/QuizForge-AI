import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('AssessmentRepository Implementation Tests', () {
    late AssessmentRepository repository;

    setUp(() {
      repository = AssessmentRepositoryImpl();
    });

    test('saveAssessment and getAssessment', () async {
      const blueprint = AssessmentBlueprint(
        id: 'bp1',
        title: 'Mock Blueprint',
        subjectCategory: 'Polity',
      );

      final assessment = Assessment(
        id: 'asmt1',
        title: 'Polity Full Test',
        description: 'Comprehensive Polity Test',
        type: AssessmentType.topicTest,
        blueprint: blueprint,
        createdAt: DateTime.now(),
      );

      await repository.saveAssessment(assessment);
      final fetched = await repository.getAssessment('asmt1');

      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Polity Full Test'));
    });

    test('createSession and updateSession', () async {
      final now = DateTime.now();
      final session = AssessmentSession(
        id: 's100',
        assessmentId: 'asmt1',
        userId: 'u1',
        status: AssessmentStatus.inProgress,
        startedAt: now,
        updatedAt: now,
      );

      final created = await repository.createSession(session);
      expect(created.id, equals('s100'));

      final updated = session.copyWith(status: AssessmentStatus.completed);
      await repository.updateSession(updated);

      final fetched = await repository.getSession('s100');
      expect(fetched?.status, equals(AssessmentStatus.completed));
    });

    test('saveResult and getResult', () async {
      final result = AssessmentResult(
        id: 'res1',
        assessmentId: 'asmt1',
        userId: 'u1',
        score: 90.0,
        percentage: 90.0,
        completedAt: DateTime.now(),
      );

      await repository.saveResult(result);
      final fetched = await repository.getResult('asmt1', 'u1');

      expect(fetched, isNotNull);
      expect(fetched!.score, equals(90.0));
    });

    test('adaptive state persistence and offline sync queue', () async {
      const state = AdaptiveAssessmentState(
        sessionId: 's100',
        currentTheta: 1.2,
        itemsAdministered: 5,
      );

      await repository.saveAdaptiveState(state);
      final fetchedState = await repository.getAdaptiveState('s100');
      expect(fetchedState?.currentTheta, equals(1.2));

      final syncCount = await repository.syncPendingAssessments();
      expect(syncCount, greaterThanOrEqualTo(0));
    });
  });
}
