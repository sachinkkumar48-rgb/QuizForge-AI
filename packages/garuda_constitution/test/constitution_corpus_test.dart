import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('GARUDA Complete Constitutional Corpus Tests (TITAN-KO-007.2)', () {
    late InMemoryConstitutionRepository repository;

    setUp(() {
      repository = InMemoryConstitutionRepository();
    });

    test('100% Coverage Test: Verifies all Parts, Schedules, Amendments, Chapters, and Articles exist', () async {
      final parts = await repository.getParts();
      final schedules = await repository.getSchedules();
      final amendments = await repository.getAmendments();
      final chapters = await repository.getChapters();
      final articles = await repository.getArticles();

      expect(parts.length, equals(26));
      expect(schedules.length, equals(12));
      expect(amendments.length, equals(106));
      expect(chapters.length, greaterThanOrEqualTo(20));
      expect(articles.length, greaterThanOrEqualTo(100));

      final partNumbers = parts.map((p) => p.partNumber).toList();
      expect(partNumbers, containsAll([
        'I', 'II', 'III', 'IV', 'IVA', 'V', 'VI', 'VII', 'VIII', 'IX', 'IXA',
        'IXB', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XIVA', 'XV', 'XVI', 'XVII',
        'XVIII', 'XIX', 'XX', 'XXI', 'XXII'
      ]));

      final scheduleNumbers = schedules.map((s) => s.scheduleNumber).toList();
      expect(scheduleNumbers, containsAll([
        '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
      ]));

      final amdNumbers = amendments.map((a) => a.amendmentNumber).toList();
      expect(amdNumbers, containsAll(['1st', '42nd', '44th', '73rd', '74th', '86th', '101st', '103rd', '104th', '105th', '106th']));
    });

    test('Amendment Repository Query Tests: findAmendment locates by number or objectId', () async {
      final amd1 = await repository.findAmendment('1st');
      expect(amd1, isNotNull);
      expect(amd1!.amendmentNumber, equals('1st'));
      expect(amd1.year, equals(1951));

      final amd42 = await repository.findAmendment('42nd');
      expect(amd42, isNotNull);
      expect(amd42!.title, contains('42nd'));

      final amd106 = await repository.findAmendment('106th');
      expect(amd106, isNotNull);
      expect(amd106!.officialName, contains('One Hundred and Sixth'));
    });

    test('Chapter Repository Query Tests: findChapter locates by ID or Part', () async {
      final chapV1 = await repository.findChapter('KO-CHAP-V-1');
      expect(chapV1, isNotNull);
      expect(chapV1!.partNumber, equals('Part V'));
      expect(chapV1.chapterNumber, equals('Chapter I'));

      final chapters = await repository.getChapters();
      expect(chapters.any((c) => c.partNumber == 'Part VI'), isTrue);
    });

    test('Relationship Integrity Tests: Auto-generated linkages across entities', () async {
      final amd101 = await repository.findAmendment('101st');
      expect(amd101, isNotNull);
      expect(amd101!.articlesAffected, contains('246A'));

      final art246A = await repository.findArticle('246A');
      expect(art246A, isNotNull);
      expect(art246A!.articleNumber, equals('246A'));

      final sched7 = await repository.findSchedule('7');
      expect(sched7, isNotNull);
      expect(sched7!.relatedArticles, contains('Art 246'));
    });

    test('Validation Engine: Seed Repository passes all 100% coverage checks with 0 errors', () async {
      final result = await ConstitutionValidator.validateRepository(repository);
      if (!result.isValid) {
        print('Validation Errors: ${result.errors}');
      }
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Analytics Engine: Reports complete 100% constitutional coverage metrics', () async {
      final report = await ConstitutionAnalyzer.analyzeRepository(repository);

      expect(report.totalParts, equals(26));
      expect(report.totalSchedules, equals(12));
      expect(report.totalAmendments, equals(106));
      expect(report.overallCoverageRate, equals(1.0));
      expect(report.bareTextCoverageRate, equals(1.0));
    });

    test('Search & Autocomplete: Search locates Parts, Schedules, Amendments, Chapters, and Articles', () async {
      final gscResults = await repository.searchObjects('GST');
      expect(gscResults.any((o) => o.objectId == 'KO-ART-246A' || o.objectId == 'KO-ART-279A' || o.objectId == 'KO-AMD-101'), isTrue);

      final antiDefectResults = await repository.searchObjects('Anti-Defection');
      expect(antiDefectResults.any((o) => o.objectId == 'KO-SCHED-10' || o.objectId == 'KO-AMD-52'), isTrue);

      final preambleResults = await repository.searchObjects('Preamble');
      expect(preambleResults.any((o) => o.objectId == 'KO_CONST_PREAMBLE'), isTrue);
    });
  });
}
