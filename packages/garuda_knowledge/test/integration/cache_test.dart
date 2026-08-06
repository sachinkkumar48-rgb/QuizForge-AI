import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeCacheManager', () {
    late KnowledgeCacheManager cache;

    setUp(() {
      cache = KnowledgeCacheManager();
    });

    test('Caches and invalidates descriptors and lookups', () {
      final desc = KnowledgePackageDescriptor(
        packageName: 'garuda_test',
        version: '1.0.0',
        registeredAt: DateTime.now(),
      );

      cache.cacheRegistration(desc);
      expect(cache.getRegistration('garuda_test'), equals(desc));

      cache.invalidateRegistration('garuda_test');
      expect(cache.getRegistration('garuda_test'), isNull);
    });
  });
}
