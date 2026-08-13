import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('Learner Domain Model Tests (TITAN-KO-018.0 P18)', () {
    test('Learner initializes cleanly with valid fields', () {
      final now = DateTime.now().toUtc();
      final learner = Learner(
        id: 'learner_101',
        name: 'Arjun Sharma',
        email: 'arjun@example.com',
        createdAt: now,
        metadata: const {'role': 'student', 'batch': '2026'},
      );

      expect(learner.id, equals('learner_101'));
      expect(learner.name, equals('Arjun Sharma'));
      expect(learner.email, equals('arjun@example.com'));
      expect(learner.createdAt, equals(now));
      expect(learner.metadata['role'], equals('student'));
    });

    test('Learner rejects empty or whitespace ID', () {
      expect(
        () => Learner(id: '', name: 'Valid Name'),
        throwsArgumentError,
      );
      expect(
        () => Learner(id: '   ', name: 'Valid Name'),
        throwsArgumentError,
      );
    });

    test('Learner rejects empty or whitespace name', () {
      expect(
        () => Learner(id: 'learner_1', name: ''),
        throwsArgumentError,
      );
      expect(
        () => Learner(id: 'learner_1', name: '  '),
        throwsArgumentError,
      );
    });

    test('Learner metadata is immutable', () {
      final learner = Learner(
        id: 'l1',
        name: 'Name',
        metadata: {'key': 'value'},
      );

      expect(
        () => (learner.metadata as Map)['key2'] = 'value2',
        throwsUnsupportedError,
      );
    });

    test('Learner value equality and hash code work correctly', () {
      final t1 = DateTime.utc(2026, 8, 15);
      final l1 = Learner(
        id: 'l1',
        name: 'Alice',
        email: 'alice@test.com',
        createdAt: t1,
        metadata: const {'a': '1'},
      );
      final l2 = Learner(
        id: 'l1',
        name: 'Alice',
        email: 'alice@test.com',
        createdAt: t1,
        metadata: const {'a': '1'},
      );
      final l3 = Learner(
        id: 'l2',
        name: 'Bob',
      );

      expect(l1, equals(l2));
      expect(l1.hashCode, equals(l2.hashCode));
      expect(l1, isNot(equals(l3)));
    });

    test('Learner serializes to and from JSON correctly', () {
      final l1 = Learner(
        id: 'learner_202',
        name: 'Priya Verma',
        email: 'priya@test.com',
        createdAt: DateTime.utc(2026, 1, 1),
        metadata: const {'level': 'advanced'},
      );

      final json = l1.toJson();
      final l2 = Learner.fromJson(json);

      expect(l2.id, equals(l1.id));
      expect(l2.name, equals(l1.name));
      expect(l2.email, equals(l1.email));
      expect(l2.createdAt, equals(l1.createdAt));
      expect(l2.metadata, equals(l1.metadata));
      expect(l2, equals(l1));
    });

    test('Learner handles optional null fields in JSON deserialization', () {
      final json = {
        'id': 'learner_303',
        'name': 'Rahul',
      };
      final learner = Learner.fromJson(json);

      expect(learner.id, equals('learner_303'));
      expect(learner.name, equals('Rahul'));
      expect(learner.email, isNull);
      expect(learner.metadata, isEmpty);
    });

    test('Learner toString exposes ID and name cleanly', () {
      final learner = Learner(id: 'l_99', name: 'Tester');
      expect(learner.toString(), contains('l_99'));
      expect(learner.toString(), contains('Tester'));
    });
  });
}
