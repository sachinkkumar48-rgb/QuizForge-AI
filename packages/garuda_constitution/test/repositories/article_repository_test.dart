import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('InMemoryConstitutionRepository Article Query Tests', () {
    late InMemoryConstitutionRepository repo;

    setUp(() {
      repo = InMemoryConstitutionRepository();
    });

    test('getArticles returns all 89 Constitution Article Knowledge Objects', () async {
      final articles = await repo.getArticles();
      expect(articles.length, equals(89));

      final numbers = articles.map((a) => a.articleNumber).toList();
      expect(numbers, containsAll([
        '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '21A',
        '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '31A',
        '31B', '31C', '31D', '32', '32A', '33', '34', '35',
        '36', '37', '38', '39', '39A', '40', '44', '45', '50', '51', '51A',
        '52', '53', '54', '72', '74', '75', '110', '123', '124', '148',
        '153', '161', '163', '200', '213', '226', '239AA', '243', '243D',
        '243Q', '243ZH', '244', '245', '246', '246A', '248', '249', '254',
        '263', '279A', '300A', '301', '311', '312', '323A', '324', '326',
        '330', '338', '343', '352', '356', '360', '368', '370', '371A',
        '393', '395'
      ]));
    });

    test('findArticle retrieves correct Article by number or objectId', () async {
      final art14 = await repo.findArticle('14');
      expect(art14, isNotNull);
      expect(art14!.articleNumber, equals('14'));
      expect(art14.officialTitle, equals('Equality before law'));

      final art21A = await repo.findArticle('21A');
      expect(art21A, isNotNull);
      expect(art21A!.articleNumber, equals('21A'));
      expect(art21A.officialTitle, equals('Right to Education'));

      final art32 = await repo.findArticle('KO-ART-32');
      expect(art32, isNotNull);
      expect(art32!.articleNumber, equals('32'));
      expect(art32.officialTitle, contains('Remedies for enforcement'));
    });

    test('getArticlesByPart retrieves all Part III articles', () async {
      final articles = await repo.getArticlesByPart('Part III');
      expect(articles.length, equals(30));
    });

    test('searchObjects finds articles by keyword, case law, or concept', () async {
      final privacyResults = await repo.searchObjects('Puttaswamy');
      expect(privacyResults.any((o) => o.objectId == 'KO-ART-21'), isTrue);

      final untouchabilityResults = await repo.searchObjects('Untouchability');
      expect(untouchabilityResults.any((o) => o.objectId == 'KO-ART-17'), isTrue);

      final ewsResults = await repo.searchObjects('EWS');
      expect(ewsResults.any((o) => o.objectId == 'KO-ART-15'), isTrue);
      expect(ewsResults.any((o) => o.objectId == 'KO-ART-16'), isTrue);

      final dpspResults = await repo.searchObjects('Minerva Mills');
      expect(dpspResults.any((o) => o.objectId == 'KO-ART-37'), isTrue);
    });

    test('findRepealedArticles verifies historical provisions 31, 31D, 32A', () async {
      final art31 = await repo.findArticle('31');
      expect(art31, isNotNull);
      expect(art31!.status, equals(ConstitutionStatus.repealed));

      final art31D = await repo.findArticle('31D');
      expect(art31D, isNotNull);
      expect(art31D!.status, equals(ConstitutionStatus.repealed));

      final art32A = await repo.findArticle('32A');
      expect(art32A, isNotNull);
      expect(art32A!.status, equals(ConstitutionStatus.repealed));
    });
  });
}
