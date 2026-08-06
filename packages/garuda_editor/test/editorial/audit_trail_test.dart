import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('EditorialAuditTrail Tests', () {
    late EditorialAuditTrail auditTrail;

    setUp(() {
      auditTrail = EditorialAuditTrail();
    });

    test('EditorialAuditTrail records and retrieves action logs accurately', () {
      auditTrail.record(
        objectId: 'ko_audit_100',
        actorId: 'editor_1',
        actorName: 'Alice Editor',
        actionType: AuditActionType.statusChange,
        summary: 'Changed status from Imported to Pending Review',
      );

      auditTrail.record(
        objectId: 'ko_audit_100',
        actorId: 'reviewer_1',
        actorName: 'Bob Reviewer',
        actionType: AuditActionType.reviewSubmitted,
        summary: 'Submitted approval review',
        comments: 'Verified evidence links.',
      );

      final trail = auditTrail.getAuditTrail('ko_audit_100');
      expect(trail.length, equals(2));
      expect(trail[0].actionType, equals(AuditActionType.statusChange));
      expect(trail[1].actionType, equals(AuditActionType.reviewSubmitted));
      expect(trail[1].comments, equals('Verified evidence links.'));
    });
  });
}
