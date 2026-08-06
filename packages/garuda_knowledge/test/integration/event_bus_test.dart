import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeEventBus Pub/Sub', () {
    late KnowledgeEventBus bus;

    setUp(() {
      bus = KnowledgeEventBus();
    });

    test('Publishes and receives events cleanly', () {
      final receivedEvents = <KnowledgeEvent>[];

      bus.subscribe<ObjectRegisteredEvent>((event) {
        receivedEvents.add(event);
      });

      bus.publish(ObjectRegisteredEvent(
        objectId: 'OBJ-TEST',
        objectType: 'constitutionArticle',
        packageName: 'garuda_constitution',
      ));

      expect(receivedEvents.length, equals(1));
      final ev = receivedEvents.first as ObjectRegisteredEvent;
      expect(ev.objectId, equals('OBJ-TEST'));
    });
  });
}
