import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';
import 'package:garuda_editor/garuda_editor.dart';


void main() {
  group('GARUDA Current Affairs Intelligence Engine Regression Suite', () {
    test('end-to-end flow: Ingest, Classify, Link, Score, Editorial, Store, Search, Digest',
        () async {
      final repository = InMemoryCurrentAffairsRepository();
      final editorialService = CurrentAffairsEditorialService();
      final pipeline = CurrentAffairsIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );

      final rawEvents = [
        {
          'id': 'reg_001',
          'headline': 'Supreme Court bench upholds Article 21 Privacy Ruling',
          'summary':
              'Bench cites Puttaswamy judgment, DPDP Act 2023, and Swaminathan Committee recommendations.',
          'content':
              'Constitutional bench decision on Fundamental Rights under Part III and Article 32. Detailed analysis of privacy law guidelines, judicial precedents, and legislative limits under Constitution of India.',
          'officialSource': 'Supreme Court of India',
          'publicationDate': '2026-06-01T10:00:00Z',
          'evidenceIds': ['ev_reg_001'],
          'importance': 'critical',
        },
        {
          'id': 'reg_002',
          'headline': 'RBI releases Monetary Policy Statement',
          'summary': 'Repo rate decision announced under RBI Act, 1934.',
          'content':
              'Inflation control measures and liquidity adjustment facility stance announced by Monetary Policy Committee.',
          'officialSource': 'Reserve Bank of India (RBI)',
          'publicationDate': '2026-06-05T11:00:00Z',
          'evidenceIds': ['ev_reg_002'],
          'importance': 'high',
        },
      ];

      // 1. Ingest
      final result = await pipeline.ingestRawEvents(rawEvents);
      expect(result.totalValidated, equals(2));

      // 2. Query Repository
      final allObjects = await repository.getAllKnowledgeObjects();
      expect(allObjects.length, equals(2));

      // 3. Verify Links and Scoring
      final scObj = allObjects.firstWhere((o) => o.id == 'reg_001');
      expect(scObj.category, equals(CurrentAffairsCategory.polity));
      expect(scObj.links.articleIds, contains('Article 21'));
      expect(scObj.links.caseLawIds, contains('K.S. Puttaswamy v. Union of India (2017)'));
      expect(scObj.intelligence.relevanceScore, greaterThan(70.0));

      // 4. Test Search
      final searchResults = await repository.searchObjects(
        const CurrentAffairsSearchQuery(act: 'Digital Personal Data Protection Act'),
      );
      expect(searchResults.length, equals(1));

      expect(searchResults.first.id, equals('reg_001'));

      // 5. Test Editorial Workflow (Advance to Approved & Publish)
      // Advance through stages: Draft -> InitialReview -> PeerReview -> Approved
      editorialService.advanceEditorialStage(objectId: scObj.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(objectId: scObj.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(objectId: scObj.id, actorId: 'ed3', actorName: 'Chief');

      final approvedObj = scObj.copyWith(editorialStatus: EditorialStatus.approved);

      final publishedObj = editorialService.publishObject(
        approvedObj,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(publishedObj.editorialStatus, equals(EditorialStatus.published));


      // 6. Test Digest Generation
      final monthlyDigest = CurrentAffairsDigestEngine.generateMonthlyMagazine(allObjects);
      expect(monthlyDigest.items.length, equals(2));
      expect(monthlyDigest.markdownContent, contains('Supreme Court bench upholds'));

      // 7. Test Analytics
      final analyticsReport = CurrentAffairsAnalytics.generateReport(allObjects);
      expect(analyticsReport.totalEventsCount, equals(2));
      expect(analyticsReport.categoryCounts[CurrentAffairsCategory.polity], equals(1));
      expect(analyticsReport.categoryCounts[CurrentAffairsCategory.economy], equals(1));
    });
  });
}
