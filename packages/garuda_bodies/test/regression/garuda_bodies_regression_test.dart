import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('GARUDA Government Bodies Library End-to-End Regression', () {
    test(
        'end-to-end flow: Seed Corpus, Validate, Ingest, Editorial, Search, Analytics, Related Bodies, Corpus Report',
        () async {
      final repository = InMemoryBodyRepository();
      final editorialService = BodyEditorialService();
      final pipeline = BodyIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );

      // 1. Ingest a real official body (GST Council — not in the seed corpus)
      // via the Pipeline.
      final rawPayload = [
        {
          'id': 'bod_gst_council',
          'officialName': 'Goods and Services Tax Council',
          'shortName': 'GST Council',
          'bodyType': 'constitutional',
          'category': 'council',
          'constitutionalBasis': 'directArticle',
          'statutoryBasis': 'constitutionItself',
          'bodyStatus': 'active',
          'bodyIndependence': 'constitutionallyIndependent',
          'yearEstablished': 2017,
          'establishingArticleIds': ['Article 279A'],
          'parentMinistry': 'Constituted under the Constitution (Article 279A)',
          'headquarters': 'New Delhi',
          'jurisdiction': 'national',
          'mandate':
              'Recommend taxes and rates of the Goods and Services Tax to the Union and States.',
          'composition':
              'Union Finance Minister (Chairperson) and State Finance/Taxation Ministers',
          'appointmentMechanism':
              'Members are the Union Finance Minister and State Finance/Taxation Ministers',
          'appointmentAuthority': 'unionCouncilOfMinisters',
          'tenure': 'Continuing body; meets as decided',
          'tenureType': 'notApplicable',
          'removalMechanism': 'Not applicable (ex-officio membership)',
          'reportingAuthority': 'unionCouncilOfMinisters',
          'relatedArticleIds': ['Article 279A', 'Article 246A'],
          'officialSource': 'https://gstcouncil.gov.in/',
          'evidenceIds': [
            'ev_gst_council_official',
            'ev_gst_council_pib',
            'ev_gst_council_portal',
          ],
          'lastVerifiedDate': '2026-06-30',
          'keywords': ['GST Council', 'Goods and Services Tax', 'GST', 'Tax Reform'],
        }
      ];

      final ingestResult = await pipeline.ingestRawPayloads(rawPayload);
      expect(ingestResult.totalValidated, equals(1));

      // 2. Query Repository
      final allBodies = await repository.getAllBodies();
      expect(allBodies.length,
          greaterThanOrEqualTo(BodySeedCorpus.expectedBodyCorpus + 1));

      final gst = await repository.getBodyById('bod_gst_council');
      expect(gst, isNotNull);
      expect(gst!.bodyType, BodyType.constitutional);
      expect(gst.evidenceIds, isNotEmpty);

      // 3. Multi-field Search
      final searchResults = await repository.searchBodies(
        const BodySearchQuery(acronym: 'GST Council'),
      );
      expect(searchResults, isNotEmpty);
      expect(searchResults.any((b) => b.id == 'bod_gst_council'), isTrue);

      final articleResults = await repository.searchBodies(
        const BodySearchQuery(article: 'Article 279A'),
      );
      expect(articleResults.any((b) => b.id == 'bod_gst_council'), isTrue);

      // 4. Editorial Workflow
      editorialService.advanceEditorialStage(
          objectId: gst.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(
          objectId: gst.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(
          objectId: gst.id, actorId: 'ed3', actorName: 'Chief');

      final approved = gst.copyWith(editorialStatus: EditorialStatus.approved);
      final published = editorialService.publishObject(
        approved,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(published.editorialStatus, EditorialStatus.published);

      // 5. Related-Body Discovery
      final related = await repository.getRelatedBodies(gst);
      expect(related, isNotEmpty);
      expect(related.every((b) => b.id != 'bod_gst_council'), isTrue);

      // 6. Analytics
      final analytics = BodyAnalyticsEngine.generateReport(
        bodies: allBodies,
        expectedBodies: BodySeedCorpus.expectedBodyCorpus,
      );
      expect(analytics.totalBodies, allBodies.length);
      expect(analytics.bodyTypeDistribution, isNotEmpty);
      expect(analytics.topLinkedArticles, isNotEmpty);
      expect(analytics.mostInterconnectedBodies, isNotEmpty);

      // 7. Corpus Coverage Report
      final corpusReport = await repository.generateCorpusReport();
      expect(corpusReport.totalImportedBodies, allBodies.length);
      expect(corpusReport.totalArticleLinks, greaterThan(0));
      expect(corpusReport.totalActLinks, greaterThan(0));
      expect(corpusReport.totalEvidenceReferences, greaterThan(0));
      expect(corpusReport.totalBodyLinks, greaterThan(0));

      // 8. Whole seed corpus is production-valid
      for (final b in BodySeedCorpus.phase1Bodies) {
        final report = BodyValidator.validate(b);
        expect(report.isValid, isTrue,
            reason: 'Seed body ${b.id} must be valid: '
                '${report.issues.map((i) => i.message).join(' | ')}');
      }
    });
  });
}
