import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('KnowledgeIdentity Tests', () {
    final now = DateTime.parse('2026-07-22T12:00:00Z');

    test('initializes with correct attributes and default version', () {
      final identity = KnowledgeIdentity(
        canonicalId: 'cko_polity_001',
        sourceId: 'pdf_upsc_ch1',
        timestamp: now,
      );

      expect(identity.canonicalId, equals('cko_polity_001'));
      expect(identity.sourceId, equals('pdf_upsc_ch1'));
      expect(identity.version, equals(1));
      expect(identity.timestamp, equals(now));
    });

    test('value equality evaluates identical identities as equal', () {
      final id1 = KnowledgeIdentity(
        canonicalId: 'cko_1',
        sourceId: 'src_1',
        version: 2,
        timestamp: now,
      );
      final id2 = KnowledgeIdentity(
        canonicalId: 'cko_1',
        sourceId: 'src_1',
        version: 2,
        timestamp: now,
      );

      expect(id1, equals(id2));
      expect(id1.hashCode, equals(id2.hashCode));
    });

    test('copyWith updates specified attributes', () {
      final original = KnowledgeIdentity(
        canonicalId: 'cko_1',
        sourceId: 'src_1',
        version: 1,
        timestamp: now,
      );
      final updated = original.copyWith(version: 2);

      expect(updated.canonicalId, equals('cko_1'));
      expect(updated.sourceId, equals('src_1'));
      expect(updated.version, equals(2));
    });

    test('toMap and fromMap achieve full round-trip serialization', () {
      final original = KnowledgeIdentity(
        canonicalId: 'cko_1',
        sourceId: 'src_1',
        version: 3,
        timestamp: now,
      );
      final map = original.toMap();
      final restored = KnowledgeIdentity.fromMap(map);

      expect(restored, equals(original));
    });

    test('throws AssertionError on empty canonicalId or sourceId', () {
      expect(
        () => KnowledgeIdentity(canonicalId: '', sourceId: 'src_1'),
        throwsAssertionError,
      );
      expect(
        () => KnowledgeIdentity(canonicalId: 'cko_1', sourceId: '   '),
        throwsAssertionError,
      );
    });
  });
}
