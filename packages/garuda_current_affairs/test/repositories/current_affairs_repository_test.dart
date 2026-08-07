import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('InMemoryCurrentAffairsRepository Tests', () {
    late InMemoryCurrentAffairsRepository repository;

    setUp(() {
      repository = InMemoryCurrentAffairsRepository();
    });

    test('should save and retrieve NewsEvent by ID', () async {
      final event = NewsEvent(
        id: 'event_001',
        headline: 'Cabinet approves Data Protection Rules',
        summary: 'Rules framed under DPDP Act, 2023.',
        content: 'Full details of government notification.',
        officialSource: 'Press Information Bureau (PIB)',
        publicationDate: DateTime(2026, 3, 15),
        category: CurrentAffairsCategory.governance,
      );

      await repository.saveNewsEvent(event);
      final retrieved = await repository.getNewsEventById('event_001');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('event_001'));
      expect(retrieved.headline, equals('Cabinet approves Data Protection Rules'));
    });

    test('should save and query Knowledge Objects by category', () async {
      final news = NewsEvent(
        id: 'event_002',
        headline: 'RBI monetary policy update',
        summary: 'Repo rate kept unchanged.',
        content: 'Monetary policy committee decision.',
        officialSource: 'Reserve Bank of India (RBI)',
        publicationDate: DateTime(2026, 4, 1),
        category: CurrentAffairsCategory.economy,
      );

      final ko = CurrentAffairsMapper.mapToKnowledgeObject(news);
      await repository.saveKnowledgeObject(ko);

      final economyList = await repository.getByCategory(CurrentAffairsCategory.economy);
      expect(economyList.length, equals(1));
      expect(economyList.first.headline, contains('RBI monetary policy'));

      final polityList = await repository.getByCategory(CurrentAffairsCategory.polity);
      expect(polityList, isEmpty);
    });

    test('should clear stored events and objects', () async {
      final event = NewsEvent(
        id: 'event_003',
        headline: 'ISRO launches Climate Satellite',
        summary: 'Earth observation satellite in orbit.',
        content: 'PSLV mission success.',
        officialSource: 'ISRO',
        publicationDate: DateTime(2026, 5, 10),
      );

      await repository.saveNewsEvent(event);
      expect((await repository.getAllNewsEvents()).length, equals(1));

      repository.clear();
      expect((await repository.getAllNewsEvents()), isEmpty);
    });
  });
}
