import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsRelationshipBuilder Tests', () {
    test('should extract Articles, Cases, Acts, and Doctrines from event text', () {
      final news = NewsEvent(
        id: 'event_rel_1',
        headline: 'Supreme Court rules on Right to Privacy under Article 21',
        summary:
            'Bench refers to Kesavananda Bharati and Puttaswamy judgments regarding Basic Structure and DPDP Act.',
        content:
            'Examining 44th Amendment, 7th Schedule, and Swaminathan Committee recommendations alongside PM-KISAN scheme.',
        officialSource: 'Supreme Court of India',
        publicationDate: DateTime(2026, 1, 10),
      );

      final links = CurrentAffairsRelationshipBuilder.buildLinks(news);

      expect(links.articleIds, contains('Article 21'));
      expect(links.caseLawIds, contains('Kesavananda Bharati v. State of Kerala (1973)'));
      expect(links.caseLawIds, contains('K.S. Puttaswamy v. Union of India (2017)'));
      expect(links.doctrineIds, contains('Basic Structure Doctrine'));
      expect(links.actIds, contains('Digital Personal Data Protection Act, 2023'));
      expect(links.scheduleIds, contains('Seventh Schedule'));

      expect(links.committeeNames, contains('Swaminathan Committee'));
      expect(links.schemeNames, contains('PM-KISAN'));
      expect(links.isEmpty, isFalse);
      expect(links.totalLinksCount, greaterThan(5));
    });

    test('should return empty KnowledgeLinkSet when no static references present', () {
      final news = NewsEvent(
        id: 'event_rel_empty',
        headline: 'Local cultural festival celebrated',
        summary: 'Community gathering event in district.',
        content: 'Annual festival tradition held peacefully.',
        officialSource: 'District Press Release',
        publicationDate: DateTime(2026, 6, 1),
      );

      final links = CurrentAffairsRelationshipBuilder.buildLinks(news);
      expect(links.isEmpty, isTrue);
      expect(links.totalLinksCount, equals(0));
    });
  });
}
