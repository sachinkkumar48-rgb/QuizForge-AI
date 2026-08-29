import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/remedial_lesson.dart';
import 'package:garuda_learning/repository/remedial_lesson_repository.dart';

void main() {
  group('InMemoryRemedialLessonRepository Tests (TITAN-KO-025.0 P25)', () {
    late InMemoryRemedialLessonRepository repository;
    final fixedDate = DateTime.utc(2026, 8, 28, 10, 0, 0);

    RemedialLesson makeLesson(
      String id,
      String objId, {
      int version = 1,
      String title = '',
    }) {
      return RemedialLesson(
        lessonId: id,
        objectiveId: objId,
        title: title.isNotEmpty ? title : 'Title for $id',
        summary: 'Summary for $id',
        learningPoints: const ['Point 1'],
        explanation: 'Explanation for $id',
        estimatedMinutes: 10,
        authoredAt: fixedDate,
        version: version,
      );
    }

    setUp(() {
      repository = InMemoryRemedialLessonRepository();
    });

    test('1. saveLesson and getLesson stores and retrieves correctly',
        () async {
      final lesson = makeLesson('rem_1', 'lo_1');
      await repository.saveLesson(lesson);

      final retrieved = await repository.getLesson('rem_1');
      expect(retrieved, equals(lesson));

      final nonExistent = await repository.getLesson('non_existent');
      expect(nonExistent, isNull);
    });

    test(
        '2. getLessonsForObjective filters by objective and sorts by version DESC',
        () async {
      final l1v1 = makeLesson('rem_lo1_v1', 'lo_1', version: 1);
      final l1v2 = makeLesson('rem_lo1_v2', 'lo_1', version: 2);
      final l2 = makeLesson('rem_lo2_v1', 'lo_2', version: 1);

      await repository.saveAll([l1v1, l2, l1v2]);

      final lo1Lessons = await repository.getLessonsForObjective('lo_1');
      expect(lo1Lessons, hasLength(2));
      // v2 must appear before v1
      expect(lo1Lessons[0].version, equals(2));
      expect(lo1Lessons[1].version, equals(1));

      final lo2Lessons = await repository.getLessonsForObjective('lo_2');
      expect(lo2Lessons, hasLength(1));
      expect(lo2Lessons.first.lessonId, equals('rem_lo2_v1'));

      final emptyLessons = await repository.getLessonsForObjective('lo_empty');
      expect(emptyLessons, isEmpty);
    });

    test('3. getAll returns all lessons deterministically sorted', () async {
      final lB = makeLesson('rem_b', 'lo_b', version: 1);
      final lA = makeLesson('rem_a', 'lo_a', version: 1);

      await repository.saveAll([lB, lA]);

      final all = await repository.getAll();
      expect(all, hasLength(2));
      expect(all[0].objectiveId, equals('lo_a'));
      expect(all[1].objectiveId, equals('lo_b'));
    });

    test('4. deleteLesson and clear removes stored lessons', () async {
      final l1 = makeLesson('rem_1', 'lo_1');
      final l2 = makeLesson('rem_2', 'lo_2');

      await repository.saveAll([l1, l2]);
      await repository.deleteLesson('rem_1');

      expect(await repository.getLesson('rem_1'), isNull);
      expect(await repository.getLesson('rem_2'), isNotNull);

      await repository.clear();
      expect(await repository.getAll(), isEmpty);
    });
  });
}
