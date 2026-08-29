import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/study_allocation_type.dart';

void main() {
  group('StudyAllocationType Enum Tests (TITAN-KO-024.0 P24)', () {
    test('1. Enum defines all 5 strategic allocation tiers in priority order',
        () {
      expect(StudyAllocationType.values, hasLength(5));
      expect(StudyAllocationType.overdueReview.index, equals(0));
      expect(StudyAllocationType.dueReview.index, equals(1));
      expect(StudyAllocationType.weakSpotPractice.index, equals(2));
      expect(StudyAllocationType.recommendedAction.index, equals(3));
      expect(StudyAllocationType.newCurriculum.index, equals(4));
    });

    test('2. displayName returns human-readable labels for all values', () {
      expect(StudyAllocationType.overdueReview.displayName,
          equals('Overdue Spaced Review'));
      expect(StudyAllocationType.dueReview.displayName,
          equals('Due Spaced Review'));
      expect(StudyAllocationType.weakSpotPractice.displayName,
          equals('Weak-Spot Practice'));
      expect(StudyAllocationType.recommendedAction.displayName,
          equals('Recommended Action'));
      expect(StudyAllocationType.newCurriculum.displayName,
          equals('New Curriculum'));
    });
  });
}
