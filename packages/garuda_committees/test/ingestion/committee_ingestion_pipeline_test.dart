import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_committees/garuda_committees.dart';

void main() {
  group('CommitteeIngestionPipeline Tests', () {
    late InMemoryCommitteeRepository repository;
    late CommitteeEditorialService editorialService;
    late CommitteeIngestionPipeline pipeline;

    setUp(() {
      repository = InMemoryCommitteeRepository(seedDefaultCorpus: false);
      editorialService = CommitteeEditorialService();
      pipeline = CommitteeIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );
    });

    test('should ingest raw JSON maps, validate, and store in repository', () async {
      final rawPayloads = [
        {
          'id': 'comm_ingest_01',
          'officialName': 'High-Level Committee on Simultaneous Elections',
          'shortName': 'One Nation One Election Committee',
          'category': 'taskForce',
          'constitutingAuthority': 'Ministry of Law and Justice',
          'chairperson': {
            'name': 'Ram Nath Kovind',
            'designation': 'Former President of India',
            'role': 'Chairperson',
          },
          'yearConstituted': 2023,
          'currentStatus': 'submitted',
          'termsOfReference': {
            'id': 'tor_simultaneous',
            'description': 'Examine framework for conducting simultaneous elections to Lok Sabha and Assemblies.',
          },
          'evidenceIds': ['ev_kovind_2024'],
        },
      ];

      final result = await pipeline.ingestRawPayloads(rawPayloads);

      expect(result.totalProcessed, equals(1));
      expect(result.totalValidated, equals(1));
      expect(result.objects.length, equals(1));

      final stored = await repository.getCommitteeById('comm_ingest_01');
      expect(stored, isNotNull);
      expect(stored!.shortName, equals('One Nation One Election Committee'));
      expect(stored.chairperson.name, equals('Ram Nath Kovind'));
    });
  });
}
