import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_committees/garuda_committees.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('GARUDA Committees & Commissions Library End-to-End Regression Suite', () {
    test('end-to-end flow: Seed Corpus, Ingest, Validate, Editorial, Search, Analytics, Corpus Report',
        () async {
      final repository = InMemoryCommitteeRepository();
      final editorialService = CommitteeEditorialService();
      final pipeline = CommitteeIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );

      // 1. Ingest additional Landmark Body via Pipeline
      final rawPayload = [
        {
          'id': 'comm_gadgil_2011',
          'officialName': 'Western Ghats Ecology Expert Panel (Gadgil Committee)',
          'shortName': 'Gadgil Committee',
          'category': 'environment',
          'constitutingAuthority': 'Ministry of Environment and Forests, Government of India',
          'relatedArticleIds': ['Article 48A', 'Article 51A'],
          'relatedActIds': ['Environment Protection Act, 1986'],
          'chairperson': {
            'name': 'Madhav Gadgil',
            'designation': 'Ecologist',
            'role': 'Chairperson',
          },
          'yearConstituted': 2010,
          'yearDissolved': 2011,
          'currentStatus': 'submitted',
          'termsOfReference': {
            'id': 'tor_gadgil',
            'description': 'Assess state of ecology of Western Ghats region and demarcate ecologically sensitive areas under EPA 1986.',
          },
          'objectives': ['Demarcate Ecologically Sensitive Zones (ESZ 1, 2, 3) across Western Ghats'],
          'recommendations': [
            {
              'id': 'rec_gadgil_esz',
              'title': 'Demarcation of 75% Western Ghats as ESZ',
              'description': 'Designate Western Ghats as Ecologically Sensitive Area under Environment Protection Act, 1986.',
              'category': 'Ecology',
              'status': 'acceptedPartially',
              'relatedActIds': ['Environment Protection Act, 1986'],
            }
          ],
          'evidenceIds': ['ev_gadgil_2011'],
          'keywords': ['Gadgil Committee', 'Western Ghats', 'Ecologically Sensitive Area', 'Environment'],
        }

      ];

      final ingestResult = await pipeline.ingestRawPayloads(rawPayload);
      expect(ingestResult.totalValidated, equals(1));

      // 2. Query Repository
      final allCommittees = await repository.getAllCommittees();
      expect(allCommittees.length, greaterThanOrEqualTo(8));

      // 3. Test Multi-field Search
      final searchResults = await repository.searchCommittees(
        const CommitteeSearchQuery(name: 'Gadgil'),
      );
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('comm_gadgil_2011'));

      // 4. Test Editorial Workflow
      final gadgilObj = searchResults.first;
      editorialService.advanceEditorialStage(objectId: gadgilObj.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(objectId: gadgilObj.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(objectId: gadgilObj.id, actorId: 'ed3', actorName: 'Chief');

      final approvedGadgil = gadgilObj.copyWith(editorialStatus: EditorialStatus.approved);
      final publishedGadgil = editorialService.publishObject(
        approvedGadgil,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(publishedGadgil.editorialStatus, equals(EditorialStatus.published));

      // 5. Test Analytics Report
      final analytics = CommitteeAnalyticsEngine.generateReport(allCommittees);
      expect(analytics.totalCommittees, equals(allCommittees.length));
      expect(analytics.categoryDistribution.containsKey(CommitteeCategory.environment), isTrue);
      expect(analytics.topLinkedArticles.containsKey('Article 263'), isTrue);

      // 6. Test Corpus Coverage Report
      final corpusReport = await repository.generateCorpusReport();
      expect(corpusReport.totalImportedCommittees, equals(allCommittees.length));
      expect(corpusReport.totalRecommendations, greaterThan(0));
    });
  });
}
