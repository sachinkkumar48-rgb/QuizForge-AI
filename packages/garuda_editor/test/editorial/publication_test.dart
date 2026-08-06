import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('PublicationService & Operations Tests', () {
    late PublicationService publicationService;
    late EditorialAuditTrail auditTrail;
    late RollbackService rollbackService;
    late KnowledgeObject validApprovedObject;

    setUp(() {
      auditTrail = EditorialAuditTrail();
      rollbackService = RollbackService(auditTrail: auditTrail);
      publicationService = PublicationService(
        auditTrail: auditTrail,
        rollbackService: rollbackService,
      );

      validApprovedObject = KnowledgeObject(
        id: 'ko_pub_100',
        title: 'Article 14 Right to Equality',
        content: 'Equality before law and equal protection of the laws within India.',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        officialSource: 'Constitution of India (Ministry of Law and Justice)',
        evidenceIds: const ['ev_eq_01', 'ev_eq_02'],
        relatedArticles: const ['Article 15', 'Article 16'],
        tags: const ['equality', 'fundamental_rights'],
        status: EditorialStatus.approved,
        isVerified: true,
      );
    });

    test('publish successfully transitions valid approved object to Published', () {
      final published = publicationService.publish(
        validApprovedObject,
        actorId: 'pub_admin_1',
        actorName: 'Publisher Admin',
      );

      expect(published.status, equals(EditorialStatus.published));
      expect(published.version, equals(validApprovedObject.version + 1));
      expect(auditTrail.getAuditTrail(published.id).isNotEmpty, isTrue);
    });

    test('unpublish changes status back to Approved', () {
      final published = publicationService.publish(
        validApprovedObject,
        actorId: 'pub_admin_1',
        actorName: 'Publisher Admin',
      );

      final unpublished = publicationService.unpublish(
        published,
        actorId: 'pub_admin_1',
        actorName: 'Publisher Admin',
        reason: 'Temporary editorial revision.',
      );

      expect(unpublished.status, equals(EditorialStatus.approved));
    });

    test('bulkPublish publishes qualified objects and collects failures for unqualified', () {
      final unqualifiedObj = KnowledgeObject(
        id: 'ko_bad_1',
        title: 'Draft missing evidence',
        content: 'Draft content.',
        subject: 'History',
        topic: 'Modern History',
        officialSource: '',
        status: EditorialStatus.draft,
      );

      final result = publicationService.bulkPublish(
        [validApprovedObject, unqualifiedObj],
        actorId: 'admin_1',
        actorName: 'Chief Admin',
      );

      expect(result.successCount, equals(1));
      expect(result.failureCount, equals(1));
      expect(result.failedObjectReasons.containsKey('ko_bad_1'), isTrue);
    });
  });
}
