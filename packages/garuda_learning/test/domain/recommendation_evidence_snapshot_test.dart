import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/recommendation_evidence_snapshot.dart';

void main() {
  group('RecommendationEvidenceSnapshot', () {
    RecommendationEvidenceSnapshot createSnapshot({
      double reviewUrgencyFactor = 0.8,
      double prerequisiteBlockerFactor = 0.3,
      double weakDomainFactor = 0.6,
      double curriculumAdvancementFactor = 0.4,
      double practiceDensityFactor = 0.5,
      double? baselineAccuracy = 0.75,
      int baselineAttemptsCount = 10,
      LearnerObjectiveStatus baselineStatus = LearnerObjectiveStatus.inProgress,
    }) {
      return RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: reviewUrgencyFactor,
        prerequisiteBlockerFactor: prerequisiteBlockerFactor,
        weakDomainFactor: weakDomainFactor,
        curriculumAdvancementFactor: curriculumAdvancementFactor,
        practiceDensityFactor: practiceDensityFactor,
        baselineAccuracy: baselineAccuracy,
        baselineAttemptsCount: baselineAttemptsCount,
        baselineStatus: baselineStatus,
      );
    }

    // -----------------------------------------------------------------------
    // Valid Construction
    // -----------------------------------------------------------------------

    group('valid construction', () {
      test('creates snapshot with all fields', () {
        final snapshot = createSnapshot();

        expect(snapshot.reviewUrgencyFactor, closeTo(0.8, 0.0001));
        expect(snapshot.prerequisiteBlockerFactor, closeTo(0.3, 0.0001));
        expect(snapshot.weakDomainFactor, closeTo(0.6, 0.0001));
        expect(snapshot.curriculumAdvancementFactor, closeTo(0.4, 0.0001));
        expect(snapshot.practiceDensityFactor, closeTo(0.5, 0.0001));
        expect(snapshot.baselineAccuracy, closeTo(0.75, 0.0001));
        expect(snapshot.baselineAttemptsCount, equals(10));
        expect(
            snapshot.baselineStatus, equals(LearnerObjectiveStatus.inProgress));
      });

      test('creates snapshot with zero baseline accuracy', () {
        final snapshot = createSnapshot(baselineAccuracy: 0.0);
        expect(snapshot.baselineAccuracy, closeTo(0.0, 0.0001));
      });

      test('creates snapshot with perfect baseline accuracy', () {
        final snapshot = createSnapshot(baselineAccuracy: 1.0);
        expect(snapshot.baselineAccuracy, closeTo(1.0, 0.0001));
      });

      test('creates snapshot with all zero factor weights', () {
        final snapshot = createSnapshot(
          reviewUrgencyFactor: 0.0,
          prerequisiteBlockerFactor: 0.0,
          weakDomainFactor: 0.0,
          curriculumAdvancementFactor: 0.0,
          practiceDensityFactor: 0.0,
        );

        expect(snapshot.reviewUrgencyFactor, closeTo(0.0, 0.0001));
        expect(snapshot.prerequisiteBlockerFactor, closeTo(0.0, 0.0001));
        expect(snapshot.weakDomainFactor, closeTo(0.0, 0.0001));
        expect(snapshot.curriculumAdvancementFactor, closeTo(0.0, 0.0001));
        expect(snapshot.practiceDensityFactor, closeTo(0.0, 0.0001));
      });

      test('creates snapshot with all maximum factor weights', () {
        final snapshot = createSnapshot(
          reviewUrgencyFactor: 1.0,
          prerequisiteBlockerFactor: 1.0,
          weakDomainFactor: 1.0,
          curriculumAdvancementFactor: 1.0,
          practiceDensityFactor: 1.0,
        );

        expect(snapshot.reviewUrgencyFactor, closeTo(1.0, 0.0001));
        expect(snapshot.prerequisiteBlockerFactor, closeTo(1.0, 0.0001));
        expect(snapshot.weakDomainFactor, closeTo(1.0, 0.0001));
        expect(snapshot.curriculumAdvancementFactor, closeTo(1.0, 0.0001));
        expect(snapshot.practiceDensityFactor, closeTo(1.0, 0.0001));
      });

      test('supports all LearnerObjectiveStatus values', () {
        for (final status in LearnerObjectiveStatus.values) {
          final snapshot = createSnapshot(baselineStatus: status);
          expect(snapshot.baselineStatus, equals(status));
        }
      });
    });

    // -----------------------------------------------------------------------
    // Missing Evidence / Null Safety
    // -----------------------------------------------------------------------

    group('missing evidence safety', () {
      test('null baselineAccuracy for zero baseline attempts', () {
        final snapshot = createSnapshot(
          baselineAccuracy: null,
          baselineAttemptsCount: 0,
          baselineStatus: LearnerObjectiveStatus.notStarted,
        );

        expect(snapshot.baselineAccuracy, isNull);
        expect(snapshot.baselineAttemptsCount, equals(0));
        expect(
          snapshot.baselineStatus,
          equals(LearnerObjectiveStatus.notStarted),
        );
      });

      test('null baselineAccuracy does not fabricate zero', () {
        final snapshot = createSnapshot(baselineAccuracy: null);
        expect(snapshot.baselineAccuracy, isNull,
            reason: 'Null must be preserved, not replaced with 0.0');
      });

      test('zero baselineAccuracy is distinct from null', () {
        final nullSnapshot = createSnapshot(baselineAccuracy: null);
        final zeroSnapshot = createSnapshot(baselineAccuracy: 0.0);

        expect(nullSnapshot.baselineAccuracy, isNull);
        expect(zeroSnapshot.baselineAccuracy, isNotNull);
        expect(zeroSnapshot.baselineAccuracy, closeTo(0.0, 0.0001));
        expect(nullSnapshot, isNot(equals(zeroSnapshot)));
      });
    });

    // -----------------------------------------------------------------------
    // Clamping & Boundary Safety
    // -----------------------------------------------------------------------

    group('clamping and boundaries', () {
      test('clamps factor weights above 1.0 to 1.0', () {
        final snapshot = createSnapshot(
          reviewUrgencyFactor: 1.5,
          prerequisiteBlockerFactor: 2.0,
          weakDomainFactor: 999.0,
          curriculumAdvancementFactor: 1.001,
          practiceDensityFactor: 100.0,
        );

        expect(snapshot.reviewUrgencyFactor, closeTo(1.0, 0.0001));
        expect(snapshot.prerequisiteBlockerFactor, closeTo(1.0, 0.0001));
        expect(snapshot.weakDomainFactor, closeTo(1.0, 0.0001));
        expect(snapshot.curriculumAdvancementFactor, closeTo(1.0, 0.0001));
        expect(snapshot.practiceDensityFactor, closeTo(1.0, 0.0001));
      });

      test('clamps factor weights below 0.0 to 0.0', () {
        final snapshot = createSnapshot(
          reviewUrgencyFactor: -0.1,
          prerequisiteBlockerFactor: -1.0,
          weakDomainFactor: -0.001,
          curriculumAdvancementFactor: -100.0,
          practiceDensityFactor: -0.5,
        );

        expect(snapshot.reviewUrgencyFactor, closeTo(0.0, 0.0001));
        expect(snapshot.prerequisiteBlockerFactor, closeTo(0.0, 0.0001));
        expect(snapshot.weakDomainFactor, closeTo(0.0, 0.0001));
        expect(snapshot.curriculumAdvancementFactor, closeTo(0.0, 0.0001));
        expect(snapshot.practiceDensityFactor, closeTo(0.0, 0.0001));
      });

      test('rejects negative baselineAttemptsCount', () {
        expect(
          () => createSnapshot(baselineAttemptsCount: -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects baselineAccuracy below 0.0', () {
        expect(
          () => createSnapshot(baselineAccuracy: -0.1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects baselineAccuracy above 1.0', () {
        expect(
          () => createSnapshot(baselineAccuracy: 1.1),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Deterministic Equality & HashCode
    // -----------------------------------------------------------------------

    group('equality and hashCode', () {
      test('equal snapshots have same equality', () {
        final a = createSnapshot();
        final b = createSnapshot();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different factor weights produce inequality', () {
        final a = createSnapshot(reviewUrgencyFactor: 0.8);
        final b = createSnapshot(reviewUrgencyFactor: 0.2);
        expect(a, isNot(equals(b)));
      });

      test('different baselineAccuracy produces inequality', () {
        final a = createSnapshot(baselineAccuracy: 0.5);
        final b = createSnapshot(baselineAccuracy: 0.6);
        expect(a, isNot(equals(b)));
      });

      test('null vs non-null baselineAccuracy produces inequality', () {
        final a = createSnapshot(baselineAccuracy: null);
        final b = createSnapshot(baselineAccuracy: 0.5);
        expect(a, isNot(equals(b)));
      });

      test('different baselineStatus produces inequality', () {
        final a =
            createSnapshot(baselineStatus: LearnerObjectiveStatus.notStarted);
        final b =
            createSnapshot(baselineStatus: LearnerObjectiveStatus.achieved);
        expect(a, isNot(equals(b)));
      });

      test('different baselineAttemptsCount produces inequality', () {
        final a = createSnapshot(baselineAttemptsCount: 5);
        final b = createSnapshot(baselineAttemptsCount: 10);
        expect(a, isNot(equals(b)));
      });
    });

    // -----------------------------------------------------------------------
    // JSON Serialization Round-Trip
    // -----------------------------------------------------------------------

    group('JSON serialization', () {
      test('round-trip with all fields', () {
        final original = createSnapshot();
        final json = original.toJson();
        final restored = RecommendationEvidenceSnapshot.fromJson(json);
        expect(restored, equals(original));
      });

      test('round-trip with null baselineAccuracy', () {
        final original = createSnapshot(
          baselineAccuracy: null,
          baselineAttemptsCount: 0,
          baselineStatus: LearnerObjectiveStatus.notStarted,
        );
        final json = original.toJson();
        final restored = RecommendationEvidenceSnapshot.fromJson(json);

        expect(restored, equals(original));
        expect(restored.baselineAccuracy, isNull);
      });

      test('toJson excludes null baselineAccuracy key', () {
        final snapshot = createSnapshot(baselineAccuracy: null);
        final json = snapshot.toJson();
        expect(json.containsKey('baselineAccuracy'), isFalse);
      });

      test('toJson includes non-null baselineAccuracy', () {
        final snapshot = createSnapshot(baselineAccuracy: 0.75);
        final json = snapshot.toJson();
        expect(json.containsKey('baselineAccuracy'), isTrue);
        expect(json['baselineAccuracy'], closeTo(0.75, 0.0001));
      });

      test('fromJson handles missing optional fields gracefully', () {
        final json = <String, dynamic>{
          'reviewUrgencyFactor': 0.5,
          'baselineAttemptsCount': 3,
          'baselineStatus': 'inProgress',
        };
        final snapshot = RecommendationEvidenceSnapshot.fromJson(json);

        expect(snapshot.reviewUrgencyFactor, closeTo(0.5, 0.0001));
        expect(snapshot.prerequisiteBlockerFactor, closeTo(0.0, 0.0001));
        expect(snapshot.weakDomainFactor, closeTo(0.0, 0.0001));
        expect(snapshot.baselineAccuracy, isNull);
        expect(snapshot.baselineAttemptsCount, equals(3));
      });
    });

    // -----------------------------------------------------------------------
    // Immutability (compile-time: @immutable + final fields)
    // -----------------------------------------------------------------------

    group('immutability', () {
      test('snapshot is immutable value object', () {
        final snapshot = createSnapshot();
        // Verify all fields are accessible and consistent across reads.
        expect(snapshot.reviewUrgencyFactor, closeTo(0.8, 0.0001));
        expect(snapshot.baselineAttemptsCount, equals(10));

        // Verify a second read yields identical values (no hidden mutation).
        expect(snapshot.reviewUrgencyFactor, closeTo(0.8, 0.0001));
        expect(snapshot.baselineAttemptsCount, equals(10));
      });
    });

    // -----------------------------------------------------------------------
    // toString
    // -----------------------------------------------------------------------

    group('toString', () {
      test('produces readable representation', () {
        final snapshot = createSnapshot();
        final str = snapshot.toString();
        expect(str, contains('RecommendationEvidenceSnapshot'));
        expect(str, contains('urgency'));
        expect(str, contains('attempts'));
      });
    });
  });
}
