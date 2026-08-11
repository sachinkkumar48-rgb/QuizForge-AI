import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Canonical provision resolution (TITAN-KO-015.0 P13).
///
/// The service resolves a provision by its verbatim corpus reference (or its
/// canonical key) through the existing P6 normalizer; equivalent textual forms
/// normalize consistently while legally distinct provisions never merge.
/// Unknown or missing input resolves to nothing and never fabricates a
/// provision.
void main() {
  final service = syntheticService();

  group('A. canonical identity', () {
    test('canonical provision keys are exposed in sorted order', () {
      expect(service.provisionIds(ProvisionType.article),
          ['100', '21', '300', '400']);
      expect(service.provisionIds(ProvisionType.act),
          ['representation of the people act 1951']);
      expect(service.provisionIds(ProvisionType.section),
          ['section 154 crpc', 'section 41 crpc']);
    });

    test('a valid article resolves by canonical reference and by key', () {
      expect(service.resolveProvisionId(ProvisionType.article, 'Article 21'),
          '21');
      expect(service.resolveProvisionId(ProvisionType.article, '21'), '21');
      expect(service.hasProvision(ProvisionType.article, 'Article 21'), isTrue);
    });

    test('equivalent textual forms fold onto one canonical key', () {
      expect(service.resolveProvisionId(ProvisionType.article, 'Article 21'),
          '21');
      expect(
          service.resolveProvisionId(ProvisionType.article, 'Art. 21'), '21');
      expect(service.resolveProvisionId(ProvisionType.article, 'article 21'),
          '21');
      expect(service.resolveProvisionId(ProvisionType.article, '  ARTICLE 21 '),
          '21');
    });

    test('an act resolves with a leading "The" folded', () {
      expect(
        service.resolveProvisionId(
            ProvisionType.act, 'Representation of the People Act, 1951'),
        'representation of the people act 1951',
      );
      expect(
        service.resolveProvisionId(
            ProvisionType.act, 'The Representation of the People Act, 1951'),
        'representation of the people act 1951',
      );
    });

    test('a section resolves via normalized text', () {
      expect(
        service.resolveProvisionId(ProvisionType.section, 'Section 154 CrPC'),
        'section 154 crpc',
      );
      expect(
        service.resolveProvisionId(ProvisionType.section, 'section 41 crpc'),
        'section 41 crpc',
      );
    });

    test('legally distinct provisions never merge', () {
      expect(service.resolveProvisionId(ProvisionType.article, 'Article 21'),
          '21');
      expect(service.resolveProvisionId(ProvisionType.article, 'Article 100'),
          '100');
      expect('21', isNot('100'));
    });
  });

  group('B. unknown / missing', () {
    test('unknown and empty identifiers return null', () {
      expect(service.resolveProvisionId(ProvisionType.article, 'Article 999'),
          isNull);
      expect(service.resolveProvisionId(ProvisionType.act, 'No Such Act 1999'),
          isNull);
      expect(
          service.resolveProvisionId(
              ProvisionType.section, 'Section 1 Nonsense Act'),
          isNull);
      expect(service.resolveProvisionId(ProvisionType.article, ''), isNull);
      expect(service.resolveProvisionId(ProvisionType.article, '   '), isNull);
      expect(
          service.hasProvision(ProvisionType.article, 'Article 999'), isFalse);
    });

    test('unknown provision never fabricates a product', () {
      expect(service.build(ProvisionType.article, 'Article 999'), isNull);
      expect(service.build(ProvisionType.act, 'No Such Act 1999'), isNull);
      expect(service.build(ProvisionType.section, 'Section 1 Nonsense Act'),
          isNull);
    });
  });

  group('C. clause forms stay distinct on the real corpus', () {
    test('Article 21A is a distinct provision key from Article 21', () {
      final real = StatuteKnowledgeProductService();
      expect(
          real.resolveProvisionId(ProvisionType.article, 'Article 21'), '21');
      expect(
          real.resolveProvisionId(ProvisionType.article, 'Article 21A'), '21a');
      expect(real.build(ProvisionType.article, 'Article 21A'), isNotNull);
      expect(
        real.build(ProvisionType.article, 'Article 21A')!.provisionId,
        '21a',
      );
      expect(
        real.build(ProvisionType.article, 'Article 21A')!.provisionId,
        isNot(real.build(ProvisionType.article, 'Article 21')!.provisionId),
      );
    });
  });
}
