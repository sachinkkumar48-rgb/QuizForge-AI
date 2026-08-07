import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('ReportEditorialService Integration Tests', () {
    late ReportEditorialService editorialService;
    late ReportKnowledgeObject testReport;

    setUp(() {
      editorialService = ReportEditorialService();
      testReport = ReportSeedCorpus.phase1Reports.first;
    });

    test('should register report into GARUDA Editorial Production Engine', () {
      expect(
        () => editorialService.submitToEditorialWorkflow(testReport),
        returnsNormally,
      );
    });

    test('should calculate quality score for report knowledge object', () {
      final approvedReport =
          testReport.copyWith(editorialStatus: EditorialStatus.approved);
      final breakdown = editorialService.calculateQualityScore(approvedReport);
      expect(breakdown.totalScore, greaterThanOrEqualTo(80.0));
    });

    test('should advance stage and publish approved report object', () {
      editorialService.submitToEditorialWorkflow(testReport);

      editorialService.advanceEditorialStage(
          objectId: testReport.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(
          objectId: testReport.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(
          objectId: testReport.id, actorId: 'ed3', actorName: 'Chief');

      final approvedObj =
          testReport.copyWith(editorialStatus: EditorialStatus.approved);

      final publishedObj = editorialService.publishObject(
        approvedObj,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );

      expect(publishedObj.editorialStatus, equals(EditorialStatus.published));
    });

    test('should bridge index and survey objects to editorial KnowledgeObjects',
        () {
      final ghi = ReportSeedCorpus.phase1Indices
          .firstWhere((i) => i.id == 'idx_ghi_2024');
      final nfhs = ReportSeedCorpus.phase1Surveys.first;

      final indexKo = ghi.toGarudaKnowledgeObject();
      final surveyKo = nfhs.toGarudaKnowledgeObject();

      expect(indexKo.knowledgeType, equals('IndexKnowledgeObject'));
      expect(indexKo.package, equals('garuda_reports'));
      expect(surveyKo.knowledgeType, equals('SurveyKnowledgeObject'));
      expect(surveyKo.evidenceIds, isNotEmpty);
    });
  });
}
