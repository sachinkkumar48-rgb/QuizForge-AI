import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

class MockSyncQueue implements KnowledgeSyncQueue {
  final List<KnowledgeSyncCommand> _queue = [];

  @override
  Future<void> enqueue(
    KnowledgeSyncOperation operation,
    KnowledgeObject object,
  ) async {
    final command = KnowledgeSyncCommand(
      id: 'cmd_${_queue.length + 1}',
      operation: operation,
      knowledgeObject: object,
    );
    _queue.add(command);
  }

  @override
  Future<void> dequeue(String id) async {
    _queue.removeWhere((cmd) => cmd.id == id);
  }

  @override
  Future<List<KnowledgeSyncCommand>> getPendingCommands() async {
    return List.unmodifiable(_queue);
  }

  @override
  Future<void> clear() async {
    _queue.clear();
  }
}

void main() {
  group('KnowledgeSyncQueue & KnowledgeSyncCommand Tests', () {
    late MockSyncQueue syncQueue;
    late KnowledgeObject sampleObject;

    setUp(() {
      syncQueue = MockSyncQueue();
      sampleObject = KnowledgeObject(
        id: 'ko_sync_1',
        type: KnowledgeType.pdf,
        title: 'Polity Notes',
        summary: 'Indian Constitution fundamentals',
        source: 'local://polity.pdf',
      );
    });

    test('KnowledgeSyncCommand value equality and props', () {
      final now = DateTime.parse('2026-07-22T12:00:00Z');
      final cmd1 = KnowledgeSyncCommand(
        id: 'cmd_1',
        operation: KnowledgeSyncOperation.save,
        knowledgeObject: sampleObject,
        enqueuedAt: now,
      );
      final cmd2 = KnowledgeSyncCommand(
        id: 'cmd_1',
        operation: KnowledgeSyncOperation.save,
        knowledgeObject: sampleObject,
        enqueuedAt: now,
      );

      expect(cmd1, equals(cmd2));
      expect(cmd1.hashCode, equals(cmd2.hashCode));
      expect(cmd1.toString(), contains('cmd_1'));
      expect(cmd1.toString(), contains('save'));
      expect(cmd1.toString(), contains('ko_sync_1'));
    });

    test('SyncQueue enqueues, fetches, dequeues and clears pending commands',
        () async {
      await syncQueue.enqueue(KnowledgeSyncOperation.save, sampleObject);
      await syncQueue.enqueue(KnowledgeSyncOperation.update,
          sampleObject.copyWith(title: 'Updated Polity Notes'));

      var pending = await syncQueue.getPendingCommands();
      expect(pending.length, equals(2));
      expect(pending.first.operation, equals(KnowledgeSyncOperation.save));
      expect(pending.last.operation, equals(KnowledgeSyncOperation.update));

      await syncQueue.dequeue(pending.first.id);
      pending = await syncQueue.getPendingCommands();
      expect(pending.length, equals(1));
      expect(pending.first.operation, equals(KnowledgeSyncOperation.update));

      await syncQueue.clear();
      pending = await syncQueue.getPendingCommands();
      expect(pending, isEmpty);
    });
  });
}
