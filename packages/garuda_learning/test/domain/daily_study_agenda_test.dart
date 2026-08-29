import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/daily_study_agenda.dart';
import 'package:garuda_learning/domain/entities/study_agenda_item.dart';
import 'package:garuda_learning/domain/entities/study_allocation_type.dart';

void main() {
  group('DailyStudyAgenda Entity Tests (TITAN-KO-024.0 P24)', () {
    final date = DateTime.utc(2026, 9, 1);

    StudyAgendaItem makeItem(
      String id,
      String objId, {
      int rank = 1,
      int minutes = 20,
      StudyAllocationType type = StudyAllocationType.dueReview,
    }) {
      return StudyAgendaItem(
        itemId: id,
        objectiveId: objId,
        allocationType: type,
        scheduledDate: date,
        allocatedMinutes: minutes,
        priorityRank: rank,
        explanation: 'Scheduled for testing',
      );
    }

    test('1. Valid construction sorts items by priorityRank', () {
      final item2 = makeItem('item_2', 'lo_2', rank: 2, minutes: 20);
      final item1 = makeItem('item_1', 'lo_1', rank: 1, minutes: 20);

      final agenda = DailyStudyAgenda(
        learnerId: 'learner_100',
        date: date,
        items: [item2, item1], // pass unsorted
        availableMinutes: 60,
      );

      expect(agenda.learnerId, equals('learner_100'));
      expect(agenda.items.first.itemId, equals('item_1'));
      expect(agenda.items.last.itemId, equals('item_2'));
      expect(agenda.sessionCount, equals(2));
      expect(agenda.allocatedMinutes, equals(40));
      expect(agenda.remainingCapacityMinutes, equals(20));
      expect(agenda.isFull, isFalse);
    });

    test('2. Rejects empty learnerId or negative availableMinutes', () {
      expect(
        () => DailyStudyAgenda(
          learnerId: '',
          date: date,
          items: [],
          availableMinutes: 60,
        ),
        throwsArgumentError,
      );

      expect(
        () => DailyStudyAgenda(
          learnerId: 'learner_100',
          date: date,
          items: [],
          availableMinutes: -5,
        ),
        throwsArgumentError,
      );
    });

    test('3. Remaining capacity clamps to 0 when allocated >= available', () {
      final item1 = makeItem('item_1', 'lo_1', rank: 1, minutes: 40);
      final item2 = makeItem('item_2', 'lo_2', rank: 2, minutes: 30);

      final agenda = DailyStudyAgenda(
        learnerId: 'learner_100',
        date: date,
        items: [item1, item2], // total 70 min
        availableMinutes: 60,
      );

      expect(agenda.allocatedMinutes, equals(70));
      expect(agenda.remainingCapacityMinutes, equals(0));
      expect(agenda.isFull, isTrue);
    });

    test('4. Objective query methods work correctly', () {
      final item1 = makeItem('item_1', 'lo_contract',
          rank: 1, minutes: 25, type: StudyAllocationType.overdueReview);
      final item2 = makeItem('item_2', 'lo_torts',
          rank: 2, minutes: 25, type: StudyAllocationType.newCurriculum);

      final agenda = DailyStudyAgenda(
        learnerId: 'learner_100',
        date: date,
        items: [item1, item2],
        availableMinutes: 60,
      );

      expect(agenda.containsObjective('lo_contract'), isTrue);
      expect(agenda.containsObjective('lo_crpc'), isFalse);
      expect(agenda.itemForObjective('lo_contract')?.itemId, equals('item_1'));
      expect(agenda.itemForObjective('lo_crpc'), isNull);

      final overdues = agenda.itemsForType(StudyAllocationType.overdueReview);
      expect(overdues, hasLength(1));
      expect(overdues.first.objectiveId, equals('lo_contract'));
    });

    test('5. JSON serialization and deserialization roundtrip', () {
      final item1 = makeItem('item_1', 'lo_1', rank: 1, minutes: 30);
      final agenda = DailyStudyAgenda(
        learnerId: 'learner_100',
        date: date,
        items: [item1],
        availableMinutes: 60,
        metadata: {'notes': 'test day'},
      );

      final json = agenda.toJson();
      final restored = DailyStudyAgenda.fromJson(json);

      expect(restored, equals(agenda));
      expect(restored.hashCode, equals(agenda.hashCode));
      expect(restored.metadata['notes'], equals('test day'));
    });
  });
}
