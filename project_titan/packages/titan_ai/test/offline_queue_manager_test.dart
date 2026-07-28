import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';

void main() {
  group('OfflineQueueManager Tests', () {
    late OfflineQueueManager manager;

    setUp(() {
      manager = OfflineQueueManager();
    });

    test('enqueues requests when offline and generates fallback response', () {
      manager.setOnlineStatus(false);
      final req = AIRequest(prompt: 'Explain Monsoon');

      final queued = manager.enqueue(req);
      expect(manager.pendingCount, equals(1));
      expect(queued.request.prompt, equals('Explain Monsoon'));

      final fallback = manager.generateOfflineFallback<String>(req);
      expect(fallback.provider, equals('offline_queue'));
      expect(fallback.finishReason, equals('OFFLINE_QUEUED'));
    });

    test('dequeues pending requests sequentially', () {
      manager.enqueue(AIRequest(prompt: 'Prompt 1'));
      manager.enqueue(AIRequest(prompt: 'Prompt 2'));

      expect(manager.pendingCount, equals(2));
      final first = manager.dequeue();
      expect(first?.request.prompt, equals('Prompt 1'));
      expect(manager.pendingCount, equals(1));
    });
  });
}
