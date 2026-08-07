import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('Scoring Engine, Validator & Editorial Integration Tests', () {
    late NewsEvent verifiedEvent;
    late CurrentAffairsKnowledgeObject ko;
    late CurrentAffairsEditorialService editorialService;

    setUp(() {
      editorialService = CurrentAffairsEditorialService();

      verifiedEvent = NewsEvent(
        id: 'ca_ed_01',
        headline: 'Supreme Court ruling on Right to Privacy under Article 21',
        summary: 'Nine-judge bench affirms Right to Privacy as fundamental right.',
        content: 'Landmark judgment by Supreme Court in Puttaswamy case regarding Article 21.',
        officialSource: 'Supreme Court of India',
        publicationDate: DateTime.now(),
        category: CurrentAffairsCategory.polity,
        importance: CurrentAffairsImportance.critical,
        evidenceIds: const ['ev_sc_privacy'],
      );

      ko = CurrentAffairsMapper.mapToKnowledgeObject(verifiedEvent);
    });

    test('CurrentAffairsScoringEngine computes high relevance score for critical event', () {
      expect(ko.intelligence.relevanceScore, greaterThanOrEqualTo(80.0));
      expect(ko.intelligence.prelimsWeight, greaterThan(0.0));
      expect(ko.intelligence.mainsWeight, greaterThan(0.0));
    });

    test('CurrentAffairsValidator passes valid verified object', () {
      final report = CurrentAffairsValidator.validate(ko);
      expect(report.isValid, isTrue);
      expect(report.issues.isEmpty, isTrue);
    });

    test('CurrentAffairsEditorialService integrates cleanly into Editorial Production Engine', () {
      editorialService.submitToEditorialWorkflow(ko);

      final registered = editorialService.workflowEngine.getKnowledgeObject(ko.id);
      expect(registered, isNotNull);
      expect(registered!.status, equals(EditorialStatus.imported));

      // Advance stage
      final adv1 = editorialService.advanceEditorialStage(
        objectId: ko.id,
        actorId: 'editor_1',
        actorName: 'Senior Editor',
      );
      expect(adv1.isSuccess, isTrue);
      expect(adv1.updatedObject.status, equals(EditorialStatus.pendingReview));
    });
  });
}
