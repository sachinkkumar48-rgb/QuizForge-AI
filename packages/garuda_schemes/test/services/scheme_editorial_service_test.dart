import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('SchemeEditorialService', () {
    final scheme = SchemeKnowledgeObject(
      id: 'sch_editorial',
      officialName: 'Editorial Scheme',
      shortName: 'ES',
      ministry: SchemeMinistry.ruralDevelopment,
      category: SchemeCategory.ruralDevelopment,
      sector: SchemeSector.ruralDevelopment,
      launchDate: DateTime(2016, 4, 1),
      beneficiaries: const [BeneficiaryGroup.ruralPoor],
      relatedArticleIds: const ['Article 19(1)(g)', 'Article 21'],
      officialSource: 'https://pmayg.nic.in/',
      evidenceIds: const [
        'ev_editorial_1',
        'ev_editorial_2',
        'ev_editorial_3',
      ],
      lastVerifiedDate: '2026-06-30',
      keywords: const ['Editorial', 'Scheme', 'Rural', 'Housing'],
    );

    test('submits into the editorial workflow and registers in the registry',
        () {
      final service = SchemeEditorialService();
      service.submitToEditorialWorkflow(scheme);

      final ko = service.workflowEngine.getKnowledgeObject('sch_editorial');
      expect(ko, isNotNull);
      expect(ko!.title, 'Editorial Scheme');
      expect(ko.knowledgeType, 'SchemeKnowledgeObject');
      expect(ko.evidenceIds, isNotEmpty);
    });

    test('advances through the sequential editorial lifecycle', () {
      final service = SchemeEditorialService();
      service.submitToEditorialWorkflow(scheme);

      final first = service.advanceEditorialStage(
        objectId: 'sch_editorial',
        actorId: 'ed1',
        actorName: 'Editor',
      );
      expect(first.isSuccess, isTrue);
      expect(first.updatedObject.status,
          isNot(EditorialStatus.imported));

      final second = service.advanceEditorialStage(
        objectId: 'sch_editorial',
        actorId: 'ed2',
        actorName: 'Peer Reviewer',
      );
      expect(second.isSuccess, isTrue);
    });

    test('calculates a quality score for the scheme', () {
      final service = SchemeEditorialService();
      final approved = scheme.copyWith(
          editorialStatus: EditorialStatus.approved);
      final score = service.calculateQualityScore(approved);
      expect(score, isNotNull);
      expect(score.totalScore, greaterThanOrEqualTo(80.0));
    });

    test('publishes only through the quality gate and updates status/version',
        () {
      final service = SchemeEditorialService();
      service.submitToEditorialWorkflow(scheme);

      final approved =
          scheme.copyWith(editorialStatus: EditorialStatus.approved);
      final published = service.publishObject(
        approved,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(published.editorialStatus, EditorialStatus.published);
      expect(published.version, greaterThan(approved.version));
    });

    test('refuses to publish an object that fails the quality gate', () {
      final service = SchemeEditorialService();
      service.submitToEditorialWorkflow(scheme);

      final gated = scheme.copyWith(
        editorialStatus: EditorialStatus.approved,
        evidenceIds: const [], // missing evidence fails the gate
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
