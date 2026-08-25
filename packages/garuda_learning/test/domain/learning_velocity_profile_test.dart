import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/learning_velocity_profile.dart';

void main() {
  group('LearningVelocityProfile Entity Tests (P23 Stage 2)', () {
    final windowStart = DateTime.utc(2026, 8, 1, 0, 0, 0);
    final windowEnd =
        DateTime.utc(2026, 8, 8, 0, 0, 0); // 7 days = 168 hours = 604800s
    final fixedTime = DateTime.utc(2026, 8, 8, 12, 0, 0);

    test('1. Valid construction with sufficient activity', () {
      final profile = LearningVelocityProfile(
        learnerId: 'learner_001',
        scopeId: 'pol_domain_fr',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsCount: 5,
        attemptsCount: 60,
        correctAttemptsCount: 48,
        newlyAchievedObjectivesCount: 7,
        activeStudyDuration: const Duration(hours: 3),
        evaluatedAt: fixedTime,
      );

      expect(profile.learnerId, equals('learner_001'));
      expect(profile.scopeId, equals('pol_domain_fr'));
      expect(profile.sessionsCount, equals(5));
      expect(profile.attemptsCount, equals(60));
      expect(profile.correctAttemptsCount, equals(48));
      expect(profile.newlyAchievedObjectivesCount, equals(7));
      expect(profile.observedAccuracy, closeTo(0.80, 0.001));
      expect(profile.attemptsPerHour, closeTo(20.0, 0.001)); // 60 / 3 hrs
      expect(
          profile.objectivesAchievedPerDay, closeTo(1.0, 0.001)); // 7 / 7 days
      expect(profile.hasSufficientEvidence, isTrue);
      expect(profile.totalWindowDuration.inDays, equals(7));
      expect(profile.averageSessionDuration.inMinutes, equals(36)); // 180m / 5
    });

    test(
        '2. Zero attempts and zero duration yields null rates without NaN or Infinity',
        () {
      final profile = LearningVelocityProfile(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsCount: 0,
        attemptsCount: 0,
        correctAttemptsCount: 0,
        newlyAchievedObjectivesCount: 0,
        activeStudyDuration: Duration.zero,
        evaluatedAt: fixedTime,
      );

      expect(profile.observedAccuracy, isNull);
      expect(profile.attemptsPerHour, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
      expect(profile.averageSessionDuration, equals(Duration.zero));
    });

    test('3. Zero-length time window handled safely', () {
      final profile = LearningVelocityProfile(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowStart, // 0 duration
        sessionsCount: 0,
        attemptsCount: 0,
        correctAttemptsCount: 0,
        newlyAchievedObjectivesCount: 0,
        evaluatedAt: fixedTime,
      );

      expect(profile.objectivesAchievedPerDay, isNull);
      expect(profile.totalWindowDuration, equals(Duration.zero));
    });

    test(
        '4. Argument validations: empty learnerId, inverted window, invalid counts',
        () {
      expect(
        () => LearningVelocityProfile(
          learnerId: '',
          windowStart: windowStart,
          windowEnd: windowEnd,
          sessionsCount: 1,
          attemptsCount: 5,
          correctAttemptsCount: 3,
          newlyAchievedObjectivesCount: 1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // windowEnd before windowStart
      expect(
        () => LearningVelocityProfile(
          learnerId: 'l_1',
          windowStart: windowEnd,
          windowEnd: windowStart,
          sessionsCount: 1,
          attemptsCount: 5,
          correctAttemptsCount: 3,
          newlyAchievedObjectivesCount: 1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // correct > attempts
      expect(
        () => LearningVelocityProfile(
          learnerId: 'l_1',
          windowStart: windowStart,
          windowEnd: windowEnd,
          sessionsCount: 1,
          attemptsCount: 5,
          correctAttemptsCount: 6,
          newlyAchievedObjectivesCount: 1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('5. JSON serialization and deserialization round-trip', () {
      final profile = LearningVelocityProfile(
        learnerId: 'learner_001',
        scopeId: 'scope_upsc',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsCount: 4,
        attemptsCount: 40,
        correctAttemptsCount: 32,
        newlyAchievedObjectivesCount: 4,
        activeStudyDuration: const Duration(hours: 2),
        metadata: const {'filter': 'polity_only'},
        evaluatedAt: fixedTime,
      );

      final json = profile.toJson();
      final reconstructed = LearningVelocityProfile.fromJson(json);

      expect(reconstructed.learnerId, equals(profile.learnerId));
      expect(reconstructed.scopeId, equals(profile.scopeId));
      expect(reconstructed.sessionsCount, equals(4));
      expect(reconstructed.attemptsCount, equals(40));
      expect(reconstructed.correctAttemptsCount, equals(32));
      expect(reconstructed.observedAccuracy, closeTo(0.80, 0.001));
      expect(reconstructed.attemptsPerHour, closeTo(20.0, 0.001));
      expect(reconstructed.activeStudyDuration.inHours, equals(2));
      expect(reconstructed.metadata['filter'], equals('polity_only'));
      expect(reconstructed, equals(profile));
    });

    test('6. Equality and hashCode contract', () {
      final p1 = LearningVelocityProfile(
        learnerId: 'l_1',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsCount: 2,
        attemptsCount: 10,
        correctAttemptsCount: 8,
        newlyAchievedObjectivesCount: 2,
        evaluatedAt: fixedTime,
      );

      final p2 = LearningVelocityProfile(
        learnerId: 'l_1',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsCount: 2,
        attemptsCount: 10,
        correctAttemptsCount: 8,
        newlyAchievedObjectivesCount: 2,
        evaluatedAt: fixedTime,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
