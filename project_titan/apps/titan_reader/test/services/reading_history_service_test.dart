import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  late InMemoryStorageService storage;
  late ReadingHistoryService history;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    history = ReadingHistoryService(storage);
  });

  test('history starts empty', () async {
    expect(await history.getVisits(), isEmpty);
    expect(await history.recentDocumentIds(), isEmpty);
  });

  test('records visits most recent first', () async {
    await history.recordVisit(
        documentId: 'a', visitedAt: DateTime.utc(2026, 8, 1));
    await history.recordVisit(
        documentId: 'b', visitedAt: DateTime.utc(2026, 8, 2));
    expect(await history.recentDocumentIds(), ['b', 'a']);
  });

  test('re-visiting moves the document to the front without duplicates',
      () async {
    await history.recordVisit(
        documentId: 'a', visitedAt: DateTime.utc(2026, 8, 1));
    await history.recordVisit(
        documentId: 'b', visitedAt: DateTime.utc(2026, 8, 2));
    await history.recordVisit(
        documentId: 'a', visitedAt: DateTime.utc(2026, 8, 3));
    final visits = await history.getVisits();
    expect(visits.map((v) => v.documentId).toList(), ['a', 'b']);
    expect(visits.first.visitedAt, DateTime.utc(2026, 8, 3));
  });

  test('history is capped at maxEntries', () async {
    for (var i = 0; i < ReadingHistoryService.maxEntries + 5; i++) {
      await history.recordVisit(
        documentId: 'doc_$i',
        visitedAt: DateTime.utc(2026, 8, 1).add(Duration(hours: i)),
      );
    }
    final visits = await history.getVisits();
    expect(visits, hasLength(ReadingHistoryService.maxEntries));
    // Newest visit survives, oldest is evicted.
    expect(
        visits.first.documentId, 'doc_${ReadingHistoryService.maxEntries + 4}');
    expect(
      visits.map((v) => v.documentId),
      isNot(contains('doc_0')),
    );
  });

  test('removeDocument drops only that document', () async {
    await history.recordVisit(
        documentId: 'a', visitedAt: DateTime.utc(2026, 8, 1));
    await history.recordVisit(
        documentId: 'b', visitedAt: DateTime.utc(2026, 8, 2));
    await history.removeDocument('a');
    expect(await history.recentDocumentIds(), ['b']);
  });

  test('malformed history payload raises a FormatException', () async {
    const key = StorageKey(ReadingHistoryService.historyKey,
        namespace: ReadingHistoryService.namespace);
    await storage.write<String>(key, '{"not":"a list"}');
    expect(() => history.getVisits(), throwsFormatException);
  });
}
