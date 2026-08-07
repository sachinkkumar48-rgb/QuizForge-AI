import 'package:garuda_connectors/garuda_connectors.dart';
import 'package:test/test.dart';

void main() {
  group('GarudaConnectorService Integration Tests', () {
    late GarudaConnectorService service;

    setUp(() {
      service = GarudaConnectorService();
    });

    test('PIBConnector is registered automatically on service creation', () {
      final pib = service.getConnector('PIB Releases');
      expect(pib, isNotNull);
      expect(pib!.metadata().connectorName, equals('PIBConnector'));
    });

    test('runIngestionPipeline collects, parses, validates, versions, and enqueues into EditorialQueue', () async {
      final processed = await service.runIngestionPipeline('PIB Releases');
      expect(processed.length, equals(2));

      // Verify stored in evidence repository
      final repoItem = await service.evidenceService.repository.findById('EV-PIB-201001');
      expect(repoItem, isNotNull);
      expect(repoItem!.title, contains('Green Hydrogen'));

      // Verify item entered EditorialQueue with pending status
      final pendingQueue = await service.evidenceService.editorialQueue.pending();
      expect(pendingQueue.length, equals(2));
      expect(pendingQueue.first.evidence.id, equals('EV-PIB-201001'));

      // Verify event log
      final events = service.getEmittedEvents();
      expect(events.any((e) => e.eventType == 'EvidenceCollected'), isTrue);
      expect(events.any((e) => e.eventType == 'EvidenceParsed'), isTrue);
      expect(events.any((e) => e.eventType == 'EvidenceValidated'), isTrue);
    });

    test('Re-ingest triggers versioning without overwriting', () async {
      // First run
      await service.runIngestionPipeline('PIB Releases');

      // Second run (simulating updated release content)
      final reProcessed = await service.runIngestionPipeline('PIB Releases');
      expect(reProcessed.length, equals(2));

      final updatedItem = await service.evidenceService.repository.findById('EV-PIB-201001');
      expect(updatedItem, isNotNull);
      expect(updatedItem!.version, equals(2));
      expect(updatedItem.versionHistory.length, equals(2));
    });
  });
}
