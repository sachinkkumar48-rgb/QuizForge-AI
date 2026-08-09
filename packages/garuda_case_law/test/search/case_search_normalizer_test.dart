import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P6.1 — deterministic normalization (TITAN-KO-015.0 P6).
void main() {
  group('normalizeText', () {
    test('lowercases and trims', () {
      expect(CaseSearchNormalizer.normalizeText('  Kesavananda Bharati  '),
          'kesavananda bharati');
    });

    test('collapses repeated whitespace', () {
      expect(CaseSearchNormalizer.normalizeText('Maneka   Gandhi   v   UOI'),
          'maneka gandhi v uoi');
    });

    test('turns punctuation into single spaces', () {
      expect(CaseSearchNormalizer.normalizeText('A.K. Gopalan v. State of M.'),
          'a k gopalan v state of m');
    });

    test('folds Art. into article', () {
      expect(CaseSearchNormalizer.normalizeText('Art. 21'), 'article 21');
      expect(CaseSearchNormalizer.normalizeText('art 21'), 'article 21');
    });

    test('folds article21 into article 21', () {
      expect(CaseSearchNormalizer.normalizeText('article21'), 'article 21');
      expect(CaseSearchNormalizer.normalizeText('art21'), 'article 21');
    });

    test('is deterministic', () {
      final a = CaseSearchNormalizer.normalizeText('Article 19 (1) (a)');
      final b = CaseSearchNormalizer.normalizeText('  ARTICLE 19 (1) (a) ');
      expect(a, b);
    });
  });

  group('normalizeArticle', () {
    test('all common variants resolve to 21', () {
      for (final variant in const ['21', 'Article 21', 'Art. 21', 'art 21', 'article21', 'ARTICLE 21']) {
        expect(CaseSearchNormalizer.normalizeArticle(variant), '21',
            reason: 'variant "$variant" must normalize to 21');
      }
    });

    test('clause-form articles preserve sub-clause digits', () {
      expect(CaseSearchNormalizer.normalizeArticle('Article 19(1)(a)'), '191a');
      expect(CaseSearchNormalizer.normalizeArticle('Article 323A'), '323a');
      expect(CaseSearchNormalizer.normalizeArticle('Art. 15(6)'), '156');
    });

    test('empty input stays empty', () {
      expect(CaseSearchNormalizer.normalizeArticle(''), '');
      expect(CaseSearchNormalizer.normalizeArticle('   '), '');
    });
  });

  group('tokenize', () {
    test('splits normalized text into word tokens', () {
      expect(CaseSearchNormalizer.tokenize('Kesavananda Bharati v. State'),
          ['kesavananda', 'bharati', 'v', 'state']);
    });

    test('drops empty tokens', () {
      expect(CaseSearchNormalizer.tokenize('   '), isEmpty);
    });
  });

  group('isPrefixOf', () {
    test('matches normalized prefix', () {
      expect(CaseSearchNormalizer.isPrefixOf('Golak', 'Golaknath Case'), isTrue);
      expect(CaseSearchNormalizer.isPrefixOf('golak', 'GOLAKNATH CASE'), isTrue);
    });

    test('rejects empty prefix', () {
      expect(CaseSearchNormalizer.isPrefixOf('', 'Golaknath'), isFalse);
    });
  });

  group('matchWeight', () {
    test('exact match is 1.0', () {
      expect(CaseSearchNormalizer.matchWeight('Kesavananda', 'Kesavananda'),
          1.0);
    });

    test('whole-value prefix is 0.7', () {
      expect(CaseSearchNormalizer.matchWeight('Golak', 'Golaknath Case'),
          0.7);
    });

    test('substring is 0.4', () {
      expect(CaseSearchNormalizer.matchWeight('nath Case', 'Golaknath Case'),
          0.4);
    });

    test('token prefix beats generic text', () {
      expect(
          CaseSearchNormalizer.matchWeight('khanna', 'H.R. Khanna J.'),
          0.6);
    });

    test('non-match is 0.0', () {
      expect(CaseSearchNormalizer.matchWeight('zzzqqq', 'Golaknath'), 0.0);
    });

    test('is deterministic', () {
      expect(CaseSearchNormalizer.matchWeight('Basic Structure',
              'The Basic Structure Doctrine'),
          CaseSearchNormalizer.matchWeight(
              'BASIC  STRUCTURE', 'the basic structure doctrine'));
    });
  });
}
