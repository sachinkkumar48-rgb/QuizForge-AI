import 'package:flutter_test/flutter_test.dart';
import 'package:titan_storage/titan_storage.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('MentorRepositoryImpl Unit Tests', () {
    late MentorRepository repository;

    setUp(() {
      repository = MentorRepositoryImpl();
    });

    test('Creates and retrieves session', () async {
      final session = await repository.createSession(
        userId: 'u_repo',
        title: 'Polity Session',
      );

      expect(session.id, isNotEmpty);
      expect(session.title, 'Polity Session');

      final list = await repository.getSessions('u_repo');
      expect(list.length, 1);
      expect(list.first.id, session.id);
    });

    test('Adds messages to session', () async {
      final session = await repository.createSession(
        userId: 'u_repo',
        title: 'History Session',
      );

      final msg = MentorMessage(
        id: 'msg_r1',
        sender: MentorMessageSender.user,
        content: 'Tell me about 1857 Revolt',
      );

      await repository.addMessage(session.id, msg);

      final updated = await repository.getSession(session.id);
      expect(updated?.messages.length, 1);
      expect(updated?.messages.first.content, 'Tell me about 1857 Revolt');
    });

    test('Deletes session', () async {
      final session = await repository.createSession(
        userId: 'u_repo',
        title: 'Session to Delete',
      );

      await repository.deleteSession(session.id);
      final found = await repository.getSession(session.id);
      expect(found, isNull);
    });

    test('Persists sessions backed by InMemoryStorageService', () async {
      final storage = InMemoryStorageService();
      await storage.initialize();

      final repo1 = MentorRepositoryImpl(storageService: storage);
      final session = await repo1.createSession(
        userId: 'u_store',
        title: 'Persisted Session',
      );

      final repo2 = MentorRepositoryImpl(storageService: storage);
      final list = await repo2.getSessions('u_store');

      expect(list.length, 1);
      expect(list.first.id, session.id);
    });
  });
}
