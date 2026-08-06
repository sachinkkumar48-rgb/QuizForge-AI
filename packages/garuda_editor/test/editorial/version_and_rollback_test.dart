import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('Versioning & RollbackService Tests', () {
    late EditorialAuditTrail auditTrail;
    late RollbackService rollbackService;
    late KnowledgeObject baseObject;
    late KnowledgeObjectVersion versionV1;

    setUp(() {
      auditTrail = EditorialAuditTrail();
      rollbackService = RollbackService(auditTrail: auditTrail);

      baseObject = KnowledgeObject(
        id: 'ko_ver_01',
        title: 'Original Title v1',
        content: 'Original Content v1',
        subject: 'Polity',
        topic: 'Preamble',
        officialSource: 'PIB Release',
        evidenceIds: const ['ev_1'],
        status: EditorialStatus.inReview,
        version: 2,
      );

      versionV1 = KnowledgeObjectVersion(
        id: 'ver_1',
        objectId: 'ko_ver_01',
        versionNumber: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        createdById: 'editor_1',
        createdByName: 'Alice Editor',
        snapshot: KnowledgeObject(
          id: 'ko_ver_01',
          title: 'Original Title v1',
          content: 'Original Content v1',
          subject: 'Polity',
          topic: 'Preamble',
          officialSource: 'PIB Release',
          evidenceIds: const ['ev_1'],
          status: EditorialStatus.inReview,
          version: 1,
        ),
      );
    });

    test('VersionComparisonService generates diff between version and object', () {
      final modifiedObject = baseObject.copyWith(
        title: 'Updated Title v2',
        content: 'Updated Content v2',
      );

      final diff = VersionComparisonService.compareWithObject(versionV1, modifiedObject);
      expect(diff.hasChanges, isTrue);
      expect(diff.diffs.length, equals(2));
      expect(diff.diffs.any((d) => d.fieldName == 'title'), isTrue);
      expect(diff.diffs.any((d) => d.fieldName == 'content'), isTrue);
    });

    test('RollbackService restores object content to target version snapshot', () {
      final modifiedObject = baseObject.copyWith(
        title: 'Corrupted Title v2',
        version: 2,
      );

      final result = rollbackService.rollbackToVersion(
        currentObject: modifiedObject,
        targetVersion: versionV1,
        actorId: 'admin_1',
        actorName: 'Chief Admin',
        reason: 'Restoring uncorrupted v1 title.',
      );

      expect(result.restoredObject.title, equals('Original Title v1'));
      expect(result.restoredObject.version, equals(3));
      expect(result.restoredObject.status, equals(EditorialStatus.pendingReview));
      expect(auditTrail.getAuditTrail('ko_ver_01').isNotEmpty, isTrue);
    });
  });
}
