import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeRegistry & Registration Service', () {
    late KnowledgeEventBus eventBus;
    late KnowledgeRegistry registry;
    late KnowledgeRepository repository;
    late KnowledgeSynchronizationService syncService;
    late KnowledgeRegistrationService registrationService;

    setUp(() {
      eventBus = KnowledgeEventBus();
      registry = KnowledgeRegistry(eventBus);
      repository = InMemoryKnowledgeRepository();
      syncService = KnowledgeSynchronizationService(repository, eventBus);
      registrationService = KnowledgeRegistrationService(registry, syncService);
    });

    test('Registers and discovers all 6 GARUDA package adapters', () async {
      final adapters = <KnowledgePackageAdapter>[
        ConstitutionPackageAdapter(),
        CaseLawPackageAdapter(),
        DoctrinePackageAdapter(),
        PyqPackageAdapter(),
        GraphPackageAdapter(),
        EvidencePackageAdapter(),
      ];

      for (final adapter in adapters) {
        await registrationService.registerAndSync(adapter);
      }

      final discovered = registry.discoverPackages();
      expect(discovered.length, equals(6));

      final graph = registry.getDependencyGraph();
      expect(graph.containsKey('garuda_constitution'), isTrue);
      expect(graph.containsKey('garuda_case_law'), isTrue);

      final allObjs = await repository.bulkExport();
      expect(allObjs.length, greaterThanOrEqualTo(6));
    });

    test('Unregisters package cleanly', () async {
      final constAdapter = ConstitutionPackageAdapter();
      await registrationService.registerAndSync(constAdapter);

      expect(registry.getPackage('garuda_constitution'), isNotNull);

      await registrationService.unregister('garuda_constitution');
      expect(registry.getPackage('garuda_constitution'), isNull);
    });
  });
}
