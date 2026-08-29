import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/study_agenda_item.dart';
import 'package:garuda_learning/domain/entities/study_allocation_type.dart';

void main() {
  group('StudyAgendaItem Entity Tests (TITAN-KO-024.0 P24)', () {
    final scheduledDate = DateTime.utc(2026, 9, 1, 14, 30, 0);
    final expectedNormalizedDate = DateTime.utc(2026, 9, 1, 0, 0, 0);

    test('1. Valid construction normalizes date to midnight UTC', () {
      final item = StudyAgendaItem(
        itemId: 'item_1',
        objectiveId: 'lo_const_law',
        allocationType: StudyAllocationType.overdueReview,
        scheduledDate: scheduledDate,
        allocatedMinutes: 30,
        priorityRank: 1,
        explanation: 'Overdue SM-2 review item by 48.0 hours',
        sourceEntityId: 'rev_1',
      );

      expect(item.itemId, equals('item_1'));
      expect(item.objectiveId, equals('lo_const_law'));
      expect(item.allocationType, equals(StudyAllocationType.overdueReview));
      expect(item.scheduledDate, equals(expectedNormalizedDate));
      expect(item.allocatedMinutes, equals(30));
      expect(item.priorityRank, equals(1));
      expect(item.explanation, contains('Overdue'));
      expect(item.sourceEntityId, equals('rev_1'));
    });

    test('2. Rejects empty itemId, objectiveId, explanation', () {
      expect(
        () => StudyAgendaItem(
          itemId: '  ',
          objectiveId: 'lo_1',
          allocationType: StudyAllocationType.dueReview,
          scheduledDate: scheduledDate,
          allocatedMinutes: 20,
          priorityRank: 1,
          explanation: 'Valid explanation',
        ),
        throwsArgumentError,
      );

      expect(
        () => StudyAgendaItem(
          itemId: 'item_1',
          objectiveId: '  ',
          allocationType: StudyAllocationType.dueReview,
          scheduledDate: scheduledDate,
          allocatedMinutes: 20,
          priorityRank: 1,
          explanation: 'Valid explanation',
        ),
        throwsArgumentError,
      );

      expect(
        () => StudyAgendaItem(
          itemId: 'item_1',
          objectiveId: 'lo_1',
          allocationType: StudyAllocationType.dueReview,
          scheduledDate: scheduledDate,
          allocatedMinutes: 20,
          priorityRank: 1,
          explanation: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('3. Rejects allocatedMinutes <= 0', () {
      expect(
        () => StudyAgendaItem(
          itemId: 'item_1',
          objectiveId: 'lo_1',
          allocationType: StudyAllocationType.dueReview,
          scheduledDate: scheduledDate,
          allocatedMinutes: 0,
          priorityRank: 1,
          explanation: 'Valid explanation',
        ),
        throwsArgumentError,
      );
    });

    test('4. Rejects priorityRank < 1', () {
      expect(
        () => StudyAgendaItem(
          itemId: 'item_1',
          objectiveId: 'lo_1',
          allocationType: StudyAllocationType.dueReview,
          scheduledDate: scheduledDate,
          allocatedMinutes: 20,
          priorityRank: 0,
          explanation: 'Valid explanation',
        ),
        throwsArgumentError,
      );
    });

    test('5. copyWith updates fields correctly', () {
      final original = StudyAgendaItem(
        itemId: 'item_1',
        objectiveId: 'lo_1',
        allocationType: StudyAllocationType.dueReview,
        scheduledDate: scheduledDate,
        allocatedMinutes: 20,
        priorityRank: 1,
        explanation: 'Due today',
      );

      final updated = original.copyWith(
        priorityRank: 2,
        allocatedMinutes: 25,
      );

      expect(updated.priorityRank, equals(2));
      expect(updated.allocatedMinutes, equals(25));
      expect(updated.itemId, equals(original.itemId));
    });

    test('6. JSON serialization and deserialization roundtrip', () {
      final item = StudyAgendaItem(
        itemId: 'item_1',
        objectiveId: 'lo_const_law',
        allocationType: StudyAllocationType.weakSpotPractice,
        scheduledDate: scheduledDate,
        allocatedMinutes: 30,
        priorityRank: 2,
        explanation: 'Weak-spot diagnostic accuracy 35.0%',
        sourceEntityId: 'diag_123',
        metadata: {'deficiency': 0.65},
      );

      final json = item.toJson();
      final restored = StudyAgendaItem.fromJson(json);

      expect(restored, equals(item));
      expect(restored.hashCode, equals(item.hashCode));
      expect(restored.metadata['deficiency'], equals(0.65));
      expect(restored.allocationType,
          equals(StudyAllocationType.weakSpotPractice));
    });
  });
}
