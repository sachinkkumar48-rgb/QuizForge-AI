import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('EditorialWorkflowEngine & State Machine Tests', () {
    late EditorialWorkflowEngine engine;
    late KnowledgeObject sampleObject;

    setUp(() {
      engine = EditorialWorkflowEngine();
      sampleObject = KnowledgeObject(
        id: 'ko_1001',
        title: 'Article 21 Right to Life & Personal Liberty',
        content: 'Detailed analysis of Article 21 and landmark judicial expansions.',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        officialSource: 'Constitution of India (Ministry of Law and Justice)',
        evidenceIds: const ['ev_2001', 'ev_2002'],
        relatedArticles: const ['Article 14', 'Article 19'],
        relatedCaseLaws: const ['Maneka Gandhi v. Union of India (1978)'],
        tags: const ['constitutional_law', 'fundamental_rights'],
        status: EditorialStatus.imported,
        isVerified: true,
      );
    });

    test('EditorialStateMachine validates sequential 10-state transitions', () {
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.imported, EditorialStatus.pendingReview),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.pendingReview, EditorialStatus.inReview),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.inReview, EditorialStatus.evidenceVerified),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.evidenceVerified, EditorialStatus.factVerified),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.factVerified, EditorialStatus.technicalReview),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.technicalReview, EditorialStatus.seniorEditorialReview),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.seniorEditorialReview, EditorialStatus.approved),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.approved, EditorialStatus.published),
          isTrue);
      expect(
          EditorialStateMachine.canTransition(
              EditorialStatus.published, EditorialStatus.archived),
          isTrue);
    });

    test('EditorialWorkflowEngine registers object and advances cleanly', () {
      engine.registerKnowledgeObject(sampleObject);
      expect(engine.queue.count, equals(1));

      final res1 = engine.advanceStage(
        objectId: sampleObject.id,
        actorId: 'editor_1',
        actorName: 'Alice Editor',
      );
      expect(res1.isSuccess, isTrue);
      expect(res1.updatedObject.status, equals(EditorialStatus.pendingReview));

      final res2 = engine.advanceStage(
        objectId: sampleObject.id,
        actorId: 'editor_1',
        actorName: 'Alice Editor',
      );
      expect(res2.isSuccess, isTrue);
      expect(res2.updatedObject.status, equals(EditorialStatus.inReview));
    });
  });
}
