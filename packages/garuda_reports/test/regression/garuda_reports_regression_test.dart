import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('GARUDA National Reports & Indices Library End-to-End Regression Suite',
      () {
    test(
        'end-to-end flow: Seed Corpus, Ingest, Validate, Editorial, Search, Analytics, Corpus Report',
        () async {
      final repository = InMemoryReportRepository();
      final editorialService = ReportEditorialService();
      final pipeline = ReportIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );

      // 1. Ingest a real official report (RBI Financial Stability Report) via Pipeline
      final rawPayload = [
        {
          'id': 'rep_rbi_fsr_2024',
          'officialTitle': 'Financial Stability Report, June 2024',
          'shortName': 'RBI Financial Stability Report',
          'category': 'finance',
          'publishingOrganisation': 'Reserve Bank of India',
          'publishingMinistry': 'Ministry of Finance',
          'publicationYear': 2024,
          'edition': 'June 2024',
          'publicationFrequency': 'semiAnnual',
          'officialUrl':
              'https://rbi.org.in/scripts/BS_PressReleaseDisplay.aspx?prid=58282',
          'executiveSummary':
              'The Financial Stability Report assesses the stability and resilience of the Indian financial system, including banking asset quality and stress-test outcomes.',
          'keyFindings': [
            'Scheduled commercial banks remain well-capitalised',
            'Stress tests indicate resilience of the banking sector',
          ],
          'keyIndicators': ['Gross NPA Ratio', 'Capital Adequacy Ratio'],
          'relatedArticleIds': ['Article 246'],
          'relatedActIds': ['Reserve Bank of India Act, 1934'],
          'chapters': [
            {
              'id': 'chp_fsr_2024_banking',
              'parentReportId': 'rep_rbi_fsr_2024',
              'chapterNumber': 'Chapter 3',
              'title': 'Banking Sector',
              'summary':
                  'Assessment of the health and resilience of scheduled commercial banks.',
              'keyPoints': [
                'Well-capitalised banking system',
                'Improving asset quality'
              ],
            }
          ],
          'evidenceIds': [
            'ev_rbi_fsr_2024',
            'ev_rbi_fsr_press_release',
            'ev_rbi_website'
          ],
          'keywords': ['RBI', 'Financial Stability', 'Banking', 'FSR'],
        }
      ];

      final ingestResult = await pipeline.ingestRawPayloads(rawPayload);
      expect(ingestResult.totalValidated, equals(1));

      // 2. Query Repository
      final allReports = await repository.getAllReports();
      expect(allReports.length,
          greaterThanOrEqualTo(ReportSeedCorpus.expectedReportCorpus + 1));

      final fsr = await repository.getReportById('rep_rbi_fsr_2024');
      expect(fsr, isNotNull);
      expect(fsr!.publishingOrganisation, equals('Reserve Bank of India'));

      // 3. Test Multi-field Search
      final searchResults = await repository.searchReports(
        const ReportSearchQuery(title: 'Financial Stability'),
      );
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('rep_rbi_fsr_2024'));

      final rbiSearch = await repository.searchReports(
        const ReportSearchQuery(publisher: 'Reserve Bank'),
      );
      expect(rbiSearch.any((r) => r.id == 'rep_rbi_fsr_2024'), isTrue);
      expect(rbiSearch.any((r) => r.id == 'rep_rbi_ar_2023_24'), isTrue);

      // 4. Editorial Workflow
      editorialService.advanceEditorialStage(
          objectId: fsr.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(
          objectId: fsr.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(
          objectId: fsr.id, actorId: 'ed3', actorName: 'Chief');

      final approvedFsr =
          fsr.copyWith(editorialStatus: EditorialStatus.approved);
      final publishedFsr = editorialService.publishObject(
        approvedFsr,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(publishedFsr.editorialStatus, equals(EditorialStatus.published));

      // 5. Analytics Report
      final analytics = ReportAnalyticsEngine.generateReport(
        reports: allReports,
        indices: await repository.getAllIndices(),
        surveys: await repository.getAllSurveys(),
        indicators: await repository.getAllIndicators(),
      );
      expect(analytics.totalReports, equals(allReports.length));
      expect(analytics.categoryDistribution.containsKey(ReportCategory.finance),
          isTrue);
      expect(analytics.topLinkedArticles.containsKey('Article 280'), isTrue);

      // 6. Indicator Graph Search
      final indicatorResults = ReportSearchEngine.searchIndicators(
        indicators: await repository.getAllIndicators(),
        query: 'Total Fertility Rate',
      );
      expect(indicatorResults, isNotEmpty);

      // 7. Corpus Coverage Report
      final corpusReport = await repository.generateCorpusReport();
      expect(corpusReport.totalImportedReports, equals(allReports.length));
      expect(corpusReport.totalRecommendations, greaterThan(0));
      expect(corpusReport.totalPyqLinks, greaterThan(0));
      expect(corpusReport.totalCurrentAffairsLinks, greaterThan(0));
    });

    test(
        'whole Phase-I corpus: every record validates, evidence resolves and PYQ references are canonical',
        () {
      final pyqFormat = RegExp(r'^PYQ_UPSC_CSE_\d{4}_GS[123]_Q\d{3}$');

      for (final report in ReportSeedCorpus.phase1Reports) {
        expect(ReportValidator.validate(report).isValid, isTrue,
            reason: 'report ${report.id} should validate clean');
        for (final ref in report.relatedPyqIds) {
          expect(pyqFormat.hasMatch(ref), isTrue,
              reason: 'report ${report.id} has non-canonical PYQ ref $ref');
        }
        expect(
          ReportCorpusSupport.hasResolvableEvidence(report),
          isTrue,
          reason: 'report ${report.id} evidence must resolve to an official URL',
        );
      }

      for (final index in ReportSeedCorpus.phase1Indices) {
        expect(ReportValidator.validateIndex(index).isValid, isTrue,
            reason: 'index ${index.id} should validate clean');
        expect(index.lastVerifiedDate, isNotEmpty);
      }

      for (final survey in ReportSeedCorpus.phase1Surveys) {
        expect(ReportValidator.validateSurvey(survey).isValid, isTrue,
            reason: 'survey ${survey.id} should validate clean');
      }

      for (final indicator in ReportSeedCorpus.phase1Indicators) {
        expect(ReportValidator.validateIndicator(indicator).isValid, isTrue,
            reason: 'indicator ${indicator.id} should validate clean');
      }

      expect(ReportSeedCorpus.corpusEvidenceCoverage, greaterThan(0.99));
    });
  });
}
