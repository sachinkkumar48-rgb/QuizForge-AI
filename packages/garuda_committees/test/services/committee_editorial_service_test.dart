import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_committees/garuda_committees.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('CommitteeEditorialService Integration Tests', () {
    late CommitteeEditorialService editorialService;
    late CommitteeKnowledgeObject testCommittee;

    setUp(() {
      editorialService = CommitteeEditorialService();
      testCommittee = CommitteeSeedCorpus.phase1Committees.first;
    });

    test('should register committee into GARUDA Editorial Production Engine', () {
      expect(
        () => editorialService.submitToEditorialWorkflow(testCommittee),
        returnsNormally,
      );
    });

    test('should calculate quality score for committee knowledge object', () {
      final approvedCommittee = testCommittee.copyWith(editorialStatus: EditorialStatus.approved);
      final breakdown = editorialService.calculateQualityScore(approvedCommittee);
      expect(breakdown.totalScore, greaterThanOrEqualTo(80.0));
    });


    test('should advance stage and publish approved committee object', () {
      editorialService.submitToEditorialWorkflow(testCommittee);

      editorialService.advanceEditorialStage(
          objectId: testCommittee.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(
          objectId: testCommittee.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(
          objectId: testCommittee.id, actorId: 'ed3', actorName: 'Chief');

      final approvedObj = testCommittee.copyWith(editorialStatus: EditorialStatus.approved);

      final publishedObj = editorialService.publishObject(
        approvedObj,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );

      expect(publishedObj.editorialStatus, equals(EditorialStatus.published));
    });
  });
}
