import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/syllabus_coverage_summary.dart';

void main() {
  group('SyllabusCoverageSummary Entity Tests (P23 Stage 1)', () {
    final fixedTime = DateTime.utc(2026, 8, 25, 12, 0, 0);

    test('1. Valid construction with partial coverage', () {
      final summary = SyllabusCoverageSummary(
        scopeId: 'framework_polity_2026',
        learnerId: 'learner_001',
        totalObjectives: 20,
        attemptedObjectives: 12,
        achievedObjectives: 8,
        evaluatedAt: fixedTime,
      );

      expect(summary.scopeId, equals('framework_polity_2026'));
      expect(summary.learnerId, equals('learner_001'));
      expect(summary.totalObjectives, equals(20));
      expect(summary.attemptedObjectives, equals(12));
      expect(summary.achievedObjectives, equals(8));
      expect(summary.inProgressObjectives, equals(4)); // 12 - 8
      expect(summary.unattemptedObjectives, equals(8)); // 20 - 12
      expect(summary.coverageRatio, closeTo(0.60, 0.001));
      expect(summary.achievementRatio, closeTo(0.40, 0.001));
      expect(summary.isFullyAttempted, isFalse);
      expect(summary.isFullyAchieved, isFalse);
    });

    test('2. Zero objectives coverage produces 0.0 without NaN or Infinity',
        () {
      final summary = SyllabusCoverageSummary(
        scopeId: 'empty_scope',
        learnerId: 'learner_001',
        totalObjectives: 0,
        attemptedObjectives: 0,
        achievedObjectives: 0,
        evaluatedAt: fixedTime,
      );

      expect(summary.coverageRatio.isNaN, isFalse);
      expect(summary.coverageRatio.isInfinite, isFalse);
      expect(summary.coverageRatio, equals(0.0));
      expect(summary.achievementRatio.isNaN, isFalse);
      expect(summary.achievementRatio.isInfinite, isFalse);
      expect(summary.achievementRatio, equals(0.0));
      expect(summary.inProgressObjectives, equals(0));
      expect(summary.unattemptedObjectives, equals(0));
      expect(summary.isFullyAttempted, isFalse);
      expect(summary.isFullyAchieved, isFalse);
    });

    test('3. Full coverage and full achievement', () {
      final summary = SyllabusCoverageSummary(
        scopeId: 'unit_fundamental_rights',
        learnerId: 'learner_001',
        totalObjectives: 5,
        attemptedObjectives: 5,
        achievedObjectives: 5,
        evaluatedAt: fixedTime,
      );

      expect(summary.coverageRatio, equals(1.0));
      expect(summary.achievementRatio, equals(1.0));
      expect(summary.inProgressObjectives, equals(0));
      expect(summary.unattemptedObjectives, equals(0));
      expect(summary.isFullyAttempted, isTrue);
      expect(summary.isFullyAchieved, isTrue);
    });

    test(
        '4. Argument validation: empty scopeId or learnerId throw ArgumentError',
        () {
      expect(
        () => SyllabusCoverageSummary(
          scopeId: '',
          learnerId: 'l_1',
          totalObjectives: 10,
          attemptedObjectives: 5,
          achievedObjectives: 2,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => SyllabusCoverageSummary(
          scopeId: 'scope_1',
          learnerId: '  ',
          totalObjectives: 10,
          attemptedObjectives: 5,
          achievedObjectives: 2,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test(
        '5. Argument validation: inconsistent objective counts throw ArgumentError',
        () {
      // attempted > total
      expect(
        () => SyllabusCoverageSummary(
          scopeId: 'scope_1',
          learnerId: 'l_1',
          totalObjectives: 5,
          attemptedObjectives: 6,
          achievedObjectives: 2,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // achieved > attempted
      expect(
        () => SyllabusCoverageSummary(
          scopeId: 'scope_1',
          learnerId: 'l_1',
          totalObjectives: 5,
          attemptedObjectives: 3,
          achievedObjectives: 4,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // negative totalObjectives
      expect(
        () => SyllabusCoverageSummary(
          scopeId: 'scope_1',
          learnerId: 'l_1',
          totalObjectives: -1,
          attemptedObjectives: 0,
          achievedObjectives: 0,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('6. JSON serialization round-trip', () {
      final summary = SyllabusCoverageSummary(
        scopeId: 'framework_polity',
        learnerId: 'learner_001',
        totalObjectives: 15,
        attemptedObjectives: 10,
        achievedObjectives: 6,
        metadata: const {'version': '1.0'},
        evaluatedAt: fixedTime,
      );

      final json = summary.toJson();
      final reconstructed = SyllabusCoverageSummary.fromJson(json);

      expect(reconstructed.scopeId, equals(summary.scopeId));
      expect(reconstructed.learnerId, equals(summary.learnerId));
      expect(reconstructed.totalObjectives, equals(15));
      expect(reconstructed.attemptedObjectives, equals(10));
      expect(reconstructed.achievedObjectives, equals(6));
      expect(reconstructed.coverageRatio, closeTo(0.666, 0.01));
      expect(reconstructed.achievementRatio, equals(0.40));
      expect(reconstructed.metadata['version'], equals('1.0'));
      expect(reconstructed, equals(summary));
    });

    test('7. Equality and hashCode contract', () {
      final s1 = SyllabusCoverageSummary(
        scopeId: 'scope_1',
        learnerId: 'l_1',
        totalObjectives: 10,
        attemptedObjectives: 5,
        achievedObjectives: 2,
        evaluatedAt: fixedTime,
      );

      final s2 = SyllabusCoverageSummary(
        scopeId: 'scope_1',
        learnerId: 'l_1',
        totalObjectives: 10,
        attemptedObjectives: 5,
        achievedObjectives: 2,
        evaluatedAt: fixedTime,
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });
  });
}
