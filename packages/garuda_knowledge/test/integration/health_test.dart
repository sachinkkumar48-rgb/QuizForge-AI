import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Package Health Monitoring', () {
    test('Calculates package health metrics correctly', () async {
      final bus = KnowledgeEventBus();
      final registry = KnowledgeRegistry(bus);

      final adapter = CaseLawPackageAdapter();
      await registry.registerPackage(adapter);

      final health = await registry.getHealth('garuda_case_law');
      expect(health.packageName, equals('garuda_case_law'));
      expect(health.status, equals(PackageHealthStatus.healthy));
      expect(health.objectCount, equals(1));
      expect(health.evidenceCount, equals(1));
      expect(health.coverage, equals(100.0));
    });
  });
}
