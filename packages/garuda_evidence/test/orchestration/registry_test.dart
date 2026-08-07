import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('EvidenceSourceRegistry & CollectorRegistry Tests', () {
    late EvidenceSourceRegistry sourceRegistry;
    late CollectorRegistry collectorRegistry;

    setUp(() {
      sourceRegistry = InMemoryEvidenceSourceRegistry();
      collectorRegistry = InMemoryCollectorRegistry();
    });

    test('SourceRegistry register, find, list, enable, disable, and unregister', () async {
      const source = EvidenceSource(
        id: 'src_pib',
        name: 'PIB Releases',
        type: EvidenceSourceType.government,
        baseUrl: 'https://pib.gov.in',
      );

      await sourceRegistry.register(source);

      final found = await sourceRegistry.find('src_pib');
      expect(found, isNotNull);
      expect(found!.name, 'PIB Releases');

      final list = await sourceRegistry.list();
      expect(list.length, equals(1));

      final disabled = await sourceRegistry.disable('src_pib');
      expect(disabled, isTrue);

      final health = await sourceRegistry.health('src_pib');
      expect(health?.status, equals(SourceHealthStatus.unavailable));

      final enabled = await sourceRegistry.enable('src_pib');
      expect(enabled, isTrue);

      final unregistered = await sourceRegistry.unregister('src_pib');
      expect(unregistered, isTrue);
      expect(await sourceRegistry.find('src_pib'), isNull);
    });

    test('CollectorRegistry register, find, supportedCollectors, and executeCollector', () async {
      final pibCollector = PIBCollector();
      await collectorRegistry.registerCollector(pibCollector);

      final collector = await collectorRegistry.findCollector('PIB Releases');
      expect(collector, isNotNull);

      final supported = await collectorRegistry.supportedCollectors();
      expect(supported, contains('PIB Releases'));

      final items = await collectorRegistry.executeCollector('PIB Releases');
      expect(items, isEmpty);

      final removed = await collectorRegistry.removeCollector('PIB Releases');
      expect(removed, isTrue);
    });
  });
}
