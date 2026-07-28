import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('TutorRepository Implementation Tests', () {
    late TutorRepository repository;

    setUp(() {
      repository = TutorRepositoryImpl();
    });

    test('createSession and getSession', () async {
      final now = DateTime.now();
      final session = TutorSession(
        id: 's100',
        learnerId: 'user1',
        conceptId: 'c1',
        status: TutorSessionStatus.active,
        startedAt: now,
        updatedAt: now,
      );

      final created = await repository.createSession(session);
      expect(created.id, equals('s100'));

      final fetched = await repository.getSession('s100');
      expect(fetched, isNotNull);
      expect(fetched!.learnerId, equals('user1'));
    });

    test('updateSession and getUserSessions', () async {
      final now = DateTime.now();
      final session = TutorSession(
        id: 's101',
        learnerId: 'user1',
        conceptId: 'c2',
        startedAt: now,
        updatedAt: now,
      );

      await repository.createSession(session);
      final updated = session.copyWith(status: TutorSessionStatus.completed);
      await repository.updateSession(updated);

      final userSessions = await repository.getUserSessions('user1');
      expect(userSessions, hasLength(1));
      expect(userSessions.first.status, equals(TutorSessionStatus.completed));
    });

    test('saveLesson and getLesson', () async {
      final lesson = TutorLesson(
        id: 'l1',
        title: 'Polity Basics',
        conceptId: 'c1',
        explanation: 'Detailed explanation',
        createdAt: DateTime.now(),
      );

      await repository.saveLesson(lesson);
      final fetched = await repository.getLesson('l1');

      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Polity Basics'));
    });

    test('progress tracking and memory caching', () async {
      final progress = TutorProgress(
        conceptId: 'c1',
        masteryLevel: 82.5,
        confidenceLevel: 0.9,
        lastAttemptAt: DateTime.now(),
      );

      await repository.updateProgress(progress);
      final fetchedProg = await repository.getProgress('c1');
      expect(fetchedProg?.masteryLevel, equals(82.5));

      final memory = TutorMemory(
        id: 'm1',
        userId: 'u1',
        conceptId: 'c1',
        strengths: ['Core principles'],
        lastInteractedAt: DateTime.now(),
      );

      await repository.saveMemory(memory);
      final fetchedMem = await repository.getMemory('u1', 'c1');
      expect(fetchedMem?.strengths, contains('Core principles'));
    });

    test('syncPendingSessions clears offline queue', () async {
      final now = DateTime.now();
      await repository.createSession(TutorSession(
        id: 's200',
        learnerId: 'u1',
        conceptId: 'c1',
        startedAt: now,
        updatedAt: now,
      ));

      final count = await repository.syncPendingSessions();
      expect(count, equals(1));

      final secondSync = await repository.syncPendingSessions();
      expect(secondSync, equals(0));
    });
  });
}
