import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeAuditTrail Logging and Retrieval', () {
    late KnowledgeAuditTrail audit;

    setUp(() {
      audit = KnowledgeAuditTrail();
    });

    test('Records audit entry and queries by package / object', () {
      final rec = AuditRecord(
        timestamp: DateTime.now(),
        packageName: 'garuda_pyq',
        objectId: 'PYQ-100',
        objectType: 'pyq',
        version: 1,
        operation: 'CREATE',
        result: 'SUCCESS',
        durationMs: 12.5,
      );

      audit.record(rec);

      expect(audit.records.length, equals(1));
      expect(audit.getRecordsByPackage('garuda_pyq').length, equals(1));
      expect(audit.getRecordsByObject('PYQ-100').length, equals(1));
    });
  });
}
