import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('BodyEditorialService', () {
    final body = BodyKnowledgeObject(
      id: 'bod_editorial',
      officialName: 'Goods and Services Tax Council',
      shortName: 'GST Council',
      bodyType: BodyType.constitutional,
      category: BodyCategory.council,
      constitutionalBasis: ConstitutionalBasis.directArticle,
      statutoryBasis: StatutoryBasis.constitutionItself,
      yearEstablished: 2017,
      establishingArticleIds: const ['Article 279A'],
      relatedArticleIds: const ['Article 279A', 'Article 246A'],
      parentMinistry: 'Constituted under the Constitution (Article 279A)',
      headquarters: 'New Delhi',
      jurisdiction: BodyJurisdiction.national,
      mandate: 'Recommend taxes and rates of the Goods and Services Tax.',
      appointmentMechanism: 'Union Finance Minister and State Finance Ministers',
      appointmentAuthority: AppointmentAuthority.unionCouncilOfMinisters,
      tenure: 'Continuing body',
      tenureType: TenureType.notApplicable,
      removalMechanism: 'Not applicable (ex-officio membership)',
      reportingAuthority: ReportingAuthority.unionCouncilOfMinisters,
      officialSource: 'https://gstcouncil.gov.in/',
      evidenceIds: const [
        'ev_gst_council_official',
        'ev_gst_council_pib',
        'ev_gst_council_portal',
      ],
      lastVerifiedDate: '2026-06-30',
      keywords: const ['GST Council', 'Goods and Services Tax', 'GST', 'Tax Reform'],
    );

    test('submits into the editorial workflow and registers in the registry',
        () {
      final service = BodyEditorialService();
      service.submitToEditorialWorkflow(body);

      final ko = service.workflowEngine.getKnowledgeObject('bod_editorial');
      expect(ko, isNotNull);
      expect(ko!.title, 'Goods and Services Tax Council');
      expect(ko.knowledgeType, 'BodyKnowledgeObject');
      expect(ko.evidenceIds, isNotEmpty);
    });

    test('advances through the sequential editorial lifecycle', () {
      final service = BodyEditorialService();
      service.submitToEditorialWorkflow(body);

      final first = service.advanceEditorialStage(
        objectId: 'bod_editorial',
        actorId: 'ed1',
        actorName: 'Editor',
      );
      expect(first.isSuccess, isTrue);
      expect(first.updatedObject.status, isNot(EditorialStatus.imported));

      final second = service.advanceEditorialStage(
        objectId: 'bod_editorial',
        actorId: 'ed2',
        actorName: 'Peer Reviewer',
      );
      expect(second.isSuccess, isTrue);
    });

    test('calculates a quality score for the body', () {
      final service = BodyEditorialService();
      final approved =
          body.copyWith(editorialStatus: EditorialStatus.approved);
      final score = service.calculateQualityScore(approved);
      expect(score, isNotNull);
      expect(score.totalScore, greaterThanOrEqualTo(80.0));
    });

    test('publishes only through the quality gate and updates status/version',
        () {
      final service = BodyEditorialService();
      service.submitToEditorialWorkflow(body);

      final approved =
          body.copyWith(editorialStatus: EditorialStatus.approved);
      final published = service.publishObject(
        approved,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(published.editorialStatus, EditorialStatus.published);
      expect(published.version, greaterThan(approved.version));
    });

    test('refuses to publish an object that fails the quality gate', () {
      final service = BodyEditorialService();
      service.submitToEditorialWorkflow(body);

      final gated = body.copyWith(
        editorialStatus: EditorialStatus.approved,
        evidenceIds: const [],
        officialSource: '',
      );

      expect(
        () => service.publishObject(
          gated,
          actorId: 'editor_001',
          actorName: 'Chief Editor',
        ),
        throwsA(anything),
      );
    });
  });
}
