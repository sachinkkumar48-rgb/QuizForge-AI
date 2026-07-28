import 'dart:async';
import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';

void main() {
  group('StreamingResponseManager Tests', () {
    late StreamingResponseManager manager;

    setUp(() {
      manager = StreamingResponseManager();
    });

    tearDown(() async {
      await manager.close();
    });

    test('processes raw text stream and accumulates deltas', () async {
      final rawController = StreamController<String>();
      final events = <StreamChunkEvent>[];

      manager.processStream(rawController.stream).listen((event) {
        events.add(event);
      });

      rawController.add('Hello ');
      rawController.add('TITAN ');
      rawController.add('AI!');
      await rawController.close();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(manager.currentText, equals('Hello TITAN AI!'));
      expect(events.last.isCompleted, isTrue);
    });

    test('handles stream errors gracefully', () async {
      final rawController = StreamController<String>();
      final events = <StreamChunkEvent>[];

      manager.processStream(rawController.stream).listen((event) {
        events.add(event);
      });

      rawController.add('Partial text ');
      rawController.addError(Exception('Network timeout'));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(manager.state, equals(StreamingState.error));
      expect(events.last.hasError, isTrue);
    });
  });
}
