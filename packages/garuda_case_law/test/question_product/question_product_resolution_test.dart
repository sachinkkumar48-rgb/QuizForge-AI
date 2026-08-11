import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P15 — source-resolution & buildAll tests (TITAN-KO-015.0 P15).
///
/// Sources are resolved deterministically by canonical ID, display name or
/// alias; unknown input resolves to nothing (never a fabricated product). The
/// corpus-wide buildAll iterates every eligible case/doctrine/provision/topic.
void main() {
  final svc = buildSyntheticQaService();

  group('A. case resolution', () {
    test('by canonical ID', () {
      expect(svc.resolveCaseId('ALPHA'), 'ALPHA');
      expect(svc.buildForCase('ALPHA')!.productId, 'qa:case:ALPHA');
    });

    test('by normalized display name', () {
      expect(svc.resolveCaseId('alpha v. state'), 'ALPHA');
      expect(svc.buildForCase('Alpha v. State'), isNotNull);
    });

    test('unknown case resolves to nothing', () {
      expect(svc.resolveCaseId('Not a Real Case'), isNull);
      expect(svc.buildForCase(''), isNull);
    });

    test('hasCase reflects resolution', () {
      expect(svc.hasCase('ALPHA'), isTrue);
      expect(svc.hasCase('NOPE'), isFalse);
    });
  });

  group('B. doctrine resolution', () {
    test('by ID and by display name', () {
      expect(svc.buildForDoctrine('SYNTH_DOCTRINE')!.productId,
          'qa:doctrine:SYNTH_DOCTRINE');
      expect(svc.buildForDoctrine('synthetic doctrine'), isNotNull);
      expect(svc.hasDoctrine('SYNTH_DOCTRINE'), isTrue);
      expect(svc.hasDoctrine('NOPE'), isFalse);
    });
  });

  group('C. statute resolution', () {
    test('article resolution by reference', () {
      final p = svc.buildForStatute(ProvisionType.article, 'Article 21');
      expect(p, isNotNull);
      expect(p!.sourceType, QuestionSourceType.statute);
      expect(svc.hasProvision(ProvisionType.article, 'Article 21'), isTrue);
      expect(svc.hasProvision(ProvisionType.article, 'Article 999'), isFalse);
    });

    test('act resolution by reference', () {
      expect(
        svc.buildForStatute(
            ProvisionType.act, 'Reasonable Restrictions Act, 2000'),
        isNotNull,
      );
    });
  });

  group('D. topic resolution', () {
    test('by ID and by display name', () {
      expect(
          svc.buildForTopic('topic_alpha')!.productId, 'qa:topic:topic_alpha');
      expect(svc.buildForTopic('Synthetic Topic Alpha'), isNotNull);
      expect(svc.hasTopic('topic_alpha'), isTrue);
      expect(svc.hasTopic('topic_nope'), isFalse);
    });
  });

  group('E. referenced / other case IDs', () {
    test('otherCaseIds excludes the source case itself', () {
      final p = svc.buildForCase('BETA')!;
      final others = svc.otherCaseIds(p);
      // BETA is the source case; ALPHA is only a P5 related case, not a content
      // reference, so neither is reported as an "other" content case.
      expect(others, isNot(contains('BETA')));
      expect(others, isNot(contains('ALPHA')));
    });

    test('otherCaseIds on a topic product lists its member cases', () {
      final p = svc.buildForTopic('topic_alpha')!;
      final others = svc.otherCaseIds(p);
      expect(others, contains('ALPHA'));
      expect(others, contains('BETA'));
    });

    test('referencedCaseIds on a topic product lists its member cases', () {
      final p = svc.buildForTopic('topic_alpha')!;
      final caseIds = svc.referencedCaseIds(p);
      expect(caseIds, contains('ALPHA'));
      expect(caseIds, contains('BETA'));
    });
  });

  group('F. buildAll', () {
    test('buildAll includes case, doctrine, statute and topic products', () {
      final all = svc.buildAll();
      final kinds = all.map((p) => p.sourceType).toSet();
      expect(kinds, {
        QuestionSourceType.caseLaw,
        QuestionSourceType.doctrine,
        QuestionSourceType.statute,
        QuestionSourceType.topic,
      });
    });

    test('every product is non-empty and has a stable product ID', () {
      for (final p in svc.buildAll()) {
        expect(p.questions, isNotEmpty);
        expect(p.productId, startsWith('qa:'));
      }
    });
  });
}
