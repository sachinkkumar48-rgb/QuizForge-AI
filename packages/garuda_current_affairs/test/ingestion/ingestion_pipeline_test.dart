import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';
import 'package:garuda_editor/garuda_editor.dart';


void main() {
  group('CurrentAffairsIngestionPipeline Tests', () {
    late InMemoryCurrentAffairsRepository repository;
    late CurrentAffairsEditorialService editorialService;
    late CurrentAffairsIngestionPipeline pipeline;

    setUp(() {
      repository = InMemoryCurrentAffairsRepository();
      editorialService = CurrentAffairsEditorialService();
      pipeline = CurrentAffairsIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );
    });

    test('should process raw JSON payloads through complete ingestion pipeline', () async {
      final rawEvents = [
        {
          'id': 'ingest_001',
          'headline': 'CAG submits Audit Report on Infrastructure Projects',
          'summary': 'Public accounts committee review mandated under Article 148.',
          'content': 'Comprehensive financial audit.',
          'officialSource': 'Comptroller and Auditor General of India (CAG)',
          'publicationDate': '2026-03-01T09:00:00Z',
          'evidenceIds': ['ev_cag_001'],
        },
        {
          'id': 'ingest_002',
          'headline': 'SEBI updates IPO Governance Framework',
          'summary': 'Disclosure guidelines for tech startups.',
          'content': 'SEBI Board decisions.',
          'officialSource': 'Securities and Exchange Board of India (SEBI)',
          'publicationDate': '2026-03-02T10:00:00Z',
          'evidenceIds': ['ev_sebi_002'],
        },
      ];

      final result = await pipeline.ingestRawEvents(rawEvents);

      expect(result.totalFetched, equals(2));
      expect(result.totalIngested, equals(2));
      expect(result.totalValidated, equals(2));
      expect(result.objects.length, equals(2));

      final savedObjects = await repository.getAllKnowledgeObjects();
      expect(savedObjects.length, equals(2));

      final firstObj = savedObjects.firstWhere((o) => o.id == 'ingest_001');
      expect(firstObj.category, equals(CurrentAffairsCategory.governance));
      expect(firstObj.officialSource, contains('CAG'));
      expect(firstObj.links.articleIds, contains('Article 148'));
      expect(firstObj.editorialStatus, equals(EditorialStatus.imported));
    });

    test('should run ingestion from official source adapter', () async {
      final adapter = PibAdapter();
      final result = await pipeline.ingestFromAdapter(adapter);

      expect(result.totalFetched, equals(0));
      expect(result.totalIngested, equals(0));
    });
  });
}
