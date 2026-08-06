import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_acts/garuda_acts.dart';

void main() {
  group('GARUDA Central Acts Library Domain Models', () {
    test('ActMetadata JSON serialization and deserialization', () {
      final meta = ActMetadata(
        officialName: 'The Bharatiya Nyaya Sanhita, 2023',
        shortTitle: 'BNS 2023',
        year: 2023,
        actNumber: '45 of 2023',
        status: ActStatus.inForce,
        category: ActCategory.criminal,
        ministry: 'Ministry of Home Affairs',
        gazetteReference: 'CG-DL-E-25122023-250883',
        officialPdfUrl: 'https://mha.gov.in/bns2023.pdf',
        commencementDate: DateTime(2024, 7, 1),
        statementOfObjectsAndReasons: 'Penal code reform',
        applicability: 'Entire Territory of India',
      );

      final json = meta.toJson();
      expect(json['shortTitle'], equals('BNS 2023'));
      expect(json['year'], equals(2023));

      final restored = ActMetadata.fromJson(json);
      expect(restored.officialName, equals(meta.officialName));
      expect(restored.category, equals(ActCategory.criminal));
    });

    test('ActSection independent addressability and serialization', () {
      final section = ActSection(
        sectionId: 'sec_bns_103',
        actId: 'act_bns_2023',
        chapterId: 'chap_bns_5',
        sectionNumber: '103',
        title: 'Punishment for Murder',
        content: 'Whoever commits murder shall be punished with death or imprisonment for life.',
        type: SectionType.penal,
        isImportant: true,
        keywords: ['Murder', 'Life Imprisonment'],
        relatedArticles: ['Article 21'],
        landmarkCases: ['Bachan Singh v. State of Punjab'],
      );

      final json = section.toJson();
      expect(json['sectionNumber'], equals('103'));
      expect(json['isImportant'], isTrue);

      final restored = ActSection.fromJson(json);
      expect(restored.sectionId, equals('sec_bns_103'));
      expect(restored.relatedArticles, contains('Article 21'));
    });
  });

  group('GARUDA Central Acts Repository', () {
    late InMemoryActRepository repo;

    setUp(() {
      repo = InMemoryActRepository();
    });

    test('Repository initializes with Phase-1 Acts seed corpus', () {
      final allActs = repo.getAllActs();
      expect(allActs.length, greaterThanOrEqualTo(15));
    });

    test('getActById returns correct Act', () {
      final act = repo.getActById('act_bns_2023');
      expect(act, isNotNull);
      expect(act!.metadata.shortTitle, contains('Bharatiya Nyaya Sanhita'));
    });

    test('getSectionsForAct returns sections correctly', () {
      final sections = repo.getSectionsForAct('act_bns_2023');
      expect(sections.isNotEmpty, isTrue);
      expect(sections.any((s) => s.sectionNumber == '103'), isTrue);
    });

    test('getActsByCategory filters correctly', () {
      final criminalActs = repo.getActsByCategory(ActCategory.criminal);
      expect(criminalActs.any((a) => a.actId == 'act_bns_2023'), isTrue);
    });
  });

  group('GARUDA Central Acts Validation Engine', () {
    test('validateCorpus returns clean report on Phase-1 corpus', () {
      final acts = Phase1ActsCorpus.phase1Acts;
      final report = ActValidator.validateCorpus(acts);

      expect(report.totalActsValidated, equals(acts.length));
      expect(report.criticalIssueCount, equals(0));
    });

    test('detects duplicate Act IDs', () {
      final act1 = Phase1ActsCorpus.phase1Acts.first;
      final report = ActValidator.validateCorpus([act1, act1]);

      expect(report.issues.any((i) => i.issueType == 'DuplicateAct'), isTrue);
    });
  });

  group('GARUDA Central Acts Multi-Faceted Search Engine', () {
    late InMemoryActRepository repo;
    late ActSearchEngine searchEngine;

    setUp(() {
      repo = InMemoryActRepository();
      searchEngine = ActSearchEngine(repo);
    });

    test('Search by Act title returns relevant Act results', () {
      final results = searchEngine.search('Nyaya Sanhita');
      expect(results.any((r) => r.resultType == 'Act'), isTrue);
    });

    test('Search by Section number returns Section result', () {
      final results = searchEngine.search('Section 103');
      expect(results.any((r) => r.resultType == 'Section'), isTrue);
    });

    test('Search by Case law name returns Case link result', () {
      final results = searchEngine.search('Bachan Singh');
      expect(results.any((r) => r.resultType == 'Case'), isTrue);
    });

    test('Search by Constitutional Article returns Article cross-link result', () {
      final results = searchEngine.search('Article 21');
      expect(results.any((r) => r.resultType == 'Article'), isTrue);
    });

    test('Autocomplete suggestions return prefix matches', () {
      final suggestions = searchEngine.getAutocompleteSuggestions('Bhara');
      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.toLowerCase().contains('bhara')), isTrue);
    });
  });

  group('GARUDA Central Acts Analytics Engine', () {
    late InMemoryActRepository repo;
    late ActAnalyticsEngine analyticsEngine;

    setUp(() {
      repo = InMemoryActRepository();
      analyticsEngine = ActAnalyticsEngine(repo);
    });

    test('generateReport calculates accurate metrics', () {
      final report = analyticsEngine.generateReport(phase1TargetCount: 30);

      expect(report.totalActsCovered, greaterThanOrEqualTo(15));
      expect(report.totalSectionsCovered, greaterThan(0));
      expect(report.totalRelationshipsCount, greaterThan(0));
      expect(report.coveragePercentage, greaterThan(0.0));
    });
  });
}
