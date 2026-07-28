import 'package:flutter_test/flutter_test.dart';
import 'package:titan_live/titan_live.dart';

void main() {
  group('LiveClassRepositoryImpl Offline Tests', () {
    late LiveClassRepository repository;

    setUp(() {
      repository = LiveClassRepositoryImpl();
    });

    test('getLiveClassById retrieves default seeded live class', () async {
      final liveClass = await repository.getLiveClassById('lc_live_01');
      expect(liveClass, isNotNull);
      expect(liveClass!.title, contains('Fundamental Rights'));
      expect(liveClass.instructorName, equals('Dr. Sharma'));
    });

    test('getUpcomingClasses returns scheduled and live classes', () async {
      final upcoming = await repository.getUpcomingClasses();
      expect(upcoming.isNotEmpty, isTrue);
    });

    test('scheduleClass and updateClass modify offline store', () async {
      final now = DateTime.now();
      final newClass = LiveClass(
        id: 'lc_test_99',
        title: 'Ethics GS IV Live Session',
        description: 'Case studies analysis.',
        subjectCategory: 'Ethics',
        instructorId: 'inst_02',
        instructorName: 'Prof. Verma',
        schedule: SessionSchedule(
          id: 'sch_99',
          liveClassId: 'lc_test_99',
          scheduledStartTime: now.add(const Duration(days: 1)),
          scheduledEndTime: now.add(const Duration(days: 1, hours: 2)),
        ),
        knowledgeNodeIds: const [],
        createdAt: now,
      );

      final scheduled = await repository.scheduleClass(newClass);
      expect(scheduled.id, equals('lc_test_99'));

      final updated = await repository
          .updateClass(scheduled.copyWith(title: 'Ethics Updated'));
      expect(updated.title, equals('Ethics Updated'));
    });

    test('joinSession and leaveSession track participant activity', () async {
      final now = DateTime.now();
      final participant = Participant(
        id: 'p_test_1',
        userId: 'u_student_1',
        name: 'Anjali',
        role: ParticipantRole.student,
        joinedAt: now,
      );

      final joined = await repository.joinSession('sess_01', participant);
      expect(joined.userId, equals('u_student_1'));

      final left = await repository.leaveSession('sess_01', 'u_student_1');
      expect(left, isTrue);
    });
  });
}
