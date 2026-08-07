import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsValidator Tests', () {
    test('should validate valid Knowledge Object with source and evidence attached', () {
      final news = NewsEvent(
        id: 'val_001',
        headline: 'Valid Event Headline',
        summary: 'Valid summary text.',
        content: 'Valid content text.',
        officialSource: 'PIB',
        publicationDate: DateTime(2026, 4, 10),
        evidenceIds: ['ev_001'],
      );

      final ko = CurrentAffairsMapper.mapToKnowledgeObject(news);
      final report = CurrentAffairsValidator.validate(ko);

      expect(report.isValid, isTrue);
      expect(report.issues, isEmpty);
    });

    test('should detect missing official source citation', () {
      final news = NewsEvent(
        id: 'val_002',
        headline: 'Event without official source',
        summary: 'Summary text.',
        content: 'Content text.',
        officialSource: '',
        publicationDate: DateTime(2026, 4, 10),
        evidenceIds: ['ev_002'],
      );

      final ko = CurrentAffairsMapper.mapToKnowledgeObject(news);
      final report = CurrentAffairsValidator.validate(ko);

      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialSource'), isTrue);
    });

    test('should detect missing evidence attachment', () {
      final news = NewsEvent(
        id: 'val_003',
        headline: 'Event without evidence',
        summary: 'Summary text.',
        content: 'Content text.',
        officialSource: 'PIB',
        publicationDate: DateTime(2026, 4, 10),
        evidenceIds: [],
      );

      final ko = CurrentAffairsMapper.mapToKnowledgeObject(news);
      final report = CurrentAffairsValidator.validate(ko);

      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'evidenceIds'), isTrue);
    });

    test('should detect duplicate event with matching headline and month', () {
      final news1 = NewsEvent(
        id: 'val_dup_1',
        headline: 'Duplicate Event Headline',
        summary: 'Summary text 1.',
        content: 'Content text 1.',
        officialSource: 'PIB',
        publicationDate: DateTime(2026, 4, 10),
        evidenceIds: ['ev_001'],
      );

      final news2 = NewsEvent(
        id: 'val_dup_2',
        headline: 'Duplicate Event Headline',
        summary: 'Summary text 2.',
        content: 'Content text 2.',
        officialSource: 'PIB',
        publicationDate: DateTime(2026, 4, 12),
        evidenceIds: ['ev_002'],
      );

      final ko1 = CurrentAffairsMapper.mapToKnowledgeObject(news1);
      final ko2 = CurrentAffairsMapper.mapToKnowledgeObject(news2);

      final report = CurrentAffairsValidator.validate(ko2, existingObjects: [ko1]);

      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'duplicate'), isTrue);
    });
  });
}
