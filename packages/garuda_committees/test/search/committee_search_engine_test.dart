import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_committees/garuda_committees.dart';

void main() {
  group('CommitteeSearchEngine Tests', () {
    late List<CommitteeKnowledgeObject> mockCommittees;

    setUp(() {
      mockCommittees = CommitteeSeedCorpus.phase1Committees;
    });

    test('should search by committee name and short name', () {
      const query = CommitteeSearchQuery(name: 'Sarkaria');
      final results = CommitteeSearchEngine.search(committees: mockCommittees, query: query);

      expect(results, isNotEmpty);
      expect(results.first.shortName, equals('Sarkaria Commission'));
    });

    test('should search by chairperson', () {
      const query = CommitteeSearchQuery(chairperson: 'Swaminathan');
      final results = CommitteeSearchEngine.search(committees: mockCommittees, query: query);

      expect(results, isNotEmpty);
      expect(results.first.shortName, equals('Swaminathan Committee'));
    });

    test('should search by linked Constitution Article', () {
      const query = CommitteeSearchQuery(article: 'Article 263');
      final results = CommitteeSearchEngine.search(committees: mockCommittees, query: query);

      expect(results, isNotEmpty);
      expect(results.any((c) => c.shortName == 'Sarkaria Commission'), isTrue);
    });

    test('should search by recommendation keyword', () {
      const query = CommitteeSearchQuery(recommendation: 'Inter-State Council');
      final results = CommitteeSearchEngine.search(committees: mockCommittees, query: query);

      expect(results, isNotEmpty);
      expect(results.first.shortName, equals('Sarkaria Commission'));
    });

    test('should generate autocomplete suggestions', () {
      final suggestions = CommitteeSearchEngine.autocomplete(
        committees: mockCommittees,
        prefix: 'Panch',
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.contains('Panchayati')), isTrue);
    });
  });
}
