import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_committees/garuda_committees.dart';

void main() {
  group('InMemoryCommitteeRepository Tests', () {
    late InMemoryCommitteeRepository repository;

    setUp(() {
      repository = InMemoryCommitteeRepository();
    });

    test('should initialize with pre-seeded Phase-I corpus', () async {
      final committees = await repository.getAllCommittees();
      expect(committees, isNotEmpty);
      expect(committees.length, greaterThanOrEqualTo(7));

      final sarkaria = await repository.getCommitteeById('comm_sarkaria_1983');
      expect(sarkaria, isNotNull);
      expect(sarkaria!.officialName, contains('Sarkaria'));
      expect(sarkaria.chairperson.name, equals('Justice R.S. Sarkaria'));
    });

    test('should save and retrieve custom Committee Knowledge Object', () async {
      final custom = CommitteeKnowledgeObject(
        id: 'comm_custom_1',
        officialName: 'Custom Tax Reform Committee',
        shortName: 'Tax Committee',
        category: CommitteeCategory.finance,
        constitutingAuthority: 'Ministry of Finance',
        chairperson: const CommitteeMember(name: 'Dr. Test Chairman', role: 'Chairperson'),
        yearConstituted: 2025,
        termsOfReference: const TermsOfReference(
          id: 'tor_custom',
          description: 'Review direct tax structure.',
        ),
      );

      await repository.saveCommittee(custom);

      final retrieved = await repository.getCommitteeById('comm_custom_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.officialName, equals('Custom Tax Reform Committee'));
    });

    test('should query committees by ministry and category', () async {
      final mhaList = await repository.getByMinistry('Ministry of Home Affairs');
      expect(mhaList, isNotEmpty);
      expect(mhaList.any((c) => c.shortName == 'Sarkaria Commission'), isTrue);

      final constList = await repository.getByCategory(CommitteeCategory.constitutional);
      expect(constList, isNotEmpty);
      expect(constList.any((c) => c.shortName == '15th Finance Commission'), isTrue);
    });

    test('should generate accurate Corpus Coverage Report', () async {
      final report = await repository.generateCorpusReport();

      expect(report.totalImportedCommittees, greaterThanOrEqualTo(7));
      expect(report.coveragePercentage, greaterThan(0));
      expect(report.totalRecommendations, greaterThan(0));
      expect(report.categoryCounts.containsKey(CommitteeCategory.executive), isTrue);
    });
  });
}
