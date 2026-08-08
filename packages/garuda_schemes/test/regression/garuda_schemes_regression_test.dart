import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('GARUDA Government Schemes Knowledge Library End-to-End Regression',
      () {
    test(
        'end-to-end flow: Seed Corpus, Validate, Ingest, Editorial, Search, Analytics, Related Schemes, Corpus Report',
        () async {
      final repository = InMemorySchemeRepository();
      final editorialService = SchemeEditorialService();
      final pipeline = SchemeIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );

      // 1. Ingest a real official scheme (Samarth — not present in the seed
      // corpus) via the Pipeline.
      final rawPayload = [
        {
          'id': 'sch_samarth_ingested',
          'officialName': 'Samarth – Scheme for Capacity Building in Textile Sector',
          'shortName': 'Samarth',
          'schemeType': 'centralSector',
          'category': 'skillDevelopment',
          'sector': 'skillDevelopment',
          'ministry': 'textiles',
          'status': 'operational',
          'launchDate': '2017-12-15',
          'funding': {
            'fundingPattern': 'fullCentral',
            'centralShare': '100% Central',
            'financialAssistance':
                'Skill training stipend to workers in the textile sector',
          },
          'beneficiaries': ['youth', 'women'],
          'targetBeneficiaries': ['Textile workers and youth'],
          'objectives': ['Skilling and upskilling of textile sector workforce'],
          'keyFeatures': ['Training aligned to the textile value chain'],
          'coverage': 'Textile sector skilling',
          'ruralUrbanScope': 'both',
          'relatedArticleIds': ['Article 21'],
          'relatedSchemeIds': ['sch_pmkvy', 'sch_skill_india'],
          'sdgGoals': ['decentWork', 'qualityEducation'],
          'officialSource': 'https://texmin.nic.in/',
          'evidenceIds': [
            'ev_samarth_official',
            'ev_samarth_pib',
            'ev_samarth_portal',
          ],
          'lastVerifiedDate': '2026-06-30',
          'keywords': ['Samarth', 'Textile', 'Skilling', 'Employment'],
        }
      ];

      final ingestResult = await pipeline.ingestRawPayloads(rawPayload);
      expect(ingestResult.totalValidated, equals(1));

      // 2. Query Repository
      final allSchemes = await repository.getAllSchemes();
      expect(allSchemes.length,
          greaterThanOrEqualTo(SchemeSeedCorpus.expectedSchemeCorpus + 1));

      final samarth = await repository.getSchemeById('sch_samarth_ingested');
      expect(samarth, isNotNull);
      expect(samarth!.ministry, SchemeMinistry.textiles);
      expect(samarth.evidenceIds, isNotEmpty);

      // 3. Multi-field Search
      final searchResults = await repository.searchSchemes(
        const SchemeSearchQuery(keyword: 'textile'),
      );
      expect(searchResults.any((s) => s.id == 'sch_samarth_ingested'), isTrue);

      final exactNameResults = await repository.searchSchemes(
        const SchemeSearchQuery(
            name: 'Samarth – Scheme for Capacity Building in Textile Sector'),
      );
      expect(exactNameResults, hasLength(1));
      expect(exactNameResults.first.id, 'sch_samarth_ingested');

      final ministryResults = await repository.searchSchemes(
        const SchemeSearchQuery(ministry: SchemeMinistry.textiles),
      );
      expect(ministryResults.any((s) => s.id == 'sch_samarth_ingested'), isTrue);

      // 4. Editorial Workflow
      editorialService.advanceEditorialStage(
          objectId: samarth.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(
          objectId: samarth.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(
          objectId: samarth.id, actorId: 'ed3', actorName: 'Chief');

      final approved =
          samarth.copyWith(editorialStatus: EditorialStatus.approved);
      final published = editorialService.publishObject(
        approved,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(published.editorialStatus, EditorialStatus.published);

      // 5. Related-Scheme Discovery
      final related = await repository.getRelatedSchemes(samarth);
      expect(related, isNotEmpty);
      expect(related.map((s) => s.id).toSet().contains('sch_pmkvy'), isTrue);

      // 6. Analytics
      final analytics = SchemeAnalyticsEngine.generateReport(
        schemes: allSchemes,
        expectedSchemes: SchemeSeedCorpus.expectedSchemeCorpus,
      );
      expect(analytics.totalSchemes, allSchemes.length);
      expect(analytics.ministryDistribution, isNotEmpty);
      expect(analytics.topLinkedArticles, isNotEmpty);
      expect(analytics.mostInterconnectedSchemes, isNotEmpty);

      // 7. Corpus Coverage Report
      final corpusReport = await repository.generateCorpusReport();
      expect(corpusReport.totalImportedSchemes, allSchemes.length);
      expect(corpusReport.totalConstitutionalLinks, greaterThan(0));
      expect(corpusReport.totalActLinks, greaterThan(0));
      expect(corpusReport.totalSdgLinks, greaterThan(0));
      expect(corpusReport.totalSchemeRelationships, greaterThan(0));

      // 8. Whole seed corpus is production-valid
      for (final s in SchemeSeedCorpus.phase1Schemes) {
        final report = SchemeValidator.validate(s);
        expect(report.isValid, isTrue,
            reason: 'Seed scheme ${s.id} must be valid: '
                '${report.issues.map((i) => i.message).join(' | ')}');
      }
    });
  });
}
