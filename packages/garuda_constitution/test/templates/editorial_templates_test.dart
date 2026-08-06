import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('Editorial Templates Tests', () {
    test('PartTemplate creates correctly structured Part object', () {
      final partObj = PartTemplate.create(
        partNumber: 'XV',
        title: 'Elections',
        officialName: 'PART XV - ELECTIONS',
        description: 'Superintendence of elections',
        articlesRange: const ['Art 324', 'Art 325'],
      );

      expect(partObj.objectId, equals('KO-PART-XV'));
      expect(partObj.title, equals('Part XV: Elections'));
      expect(partObj.relatedArticles, equals(['Art 324', 'Art 325']));
      expect(partObj.editorialStatus, equals('APPROVED'));
    });

    test('ScheduleTemplate creates correctly structured Schedule object', () {
      final schedObj = ScheduleTemplate.create(
        scheduleNumber: '8',
        title: 'Languages',
        officialName: 'EIGHTH SCHEDULE',
        description: 'Official languages',
        type: ScheduleType.officialLanguages,
      );

      expect(schedObj.objectId, equals('KO-SCHED-8'));
      expect(schedObj.title, equals('Schedule 8: Languages'));
      expect(schedObj.status, equals(ConstitutionStatus.active));
    });

    test('ArticleTemplate creates reusable draft Article template', () {
      final artObj = ArticleTemplate.create(
        articleNumber: '21',
        title: 'Protection of life and personal liberty',
        officialText: 'No person shall be deprived of his life...',
        partId: 'KO-PART-III',
      );

      expect(artObj.objectId, equals('KO-ART-21'));
      expect(artObj.relatedParts, contains('KO-PART-III'));
      expect(artObj.editorialStatus, equals('TEMPLATE_DRAFT'));
    });

    test('AmendmentTemplate creates reusable draft Amendment template', () {
      final amdObj = AmendmentTemplate.create(
        amendmentNumber: '42nd',
        actTitle: 'The Constitution (Forty-second Amendment) Act, 1976',
        dateEnacted: DateTime(1976, 12, 18),
        summary: 'Added Secular, Socialist to Preamble and Part IVA.',
        affectedParts: const ['KO-PART-IVA'],
      );

      expect(amdObj.objectId, equals('KO-AMD-42nd'));
      expect(amdObj.affectedParts, contains('KO-PART-IVA'));
      expect(amdObj.editorialStatus, equals('TEMPLATE_DRAFT'));
    });
  });
}
