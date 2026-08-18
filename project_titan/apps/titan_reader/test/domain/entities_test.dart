import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/document_privacy_state.dart';
import 'package:titan_reader/src/domain/entities/reader_document.dart';
import 'package:titan_reader/src/domain/entities/reading_position.dart';
import 'package:titan_reader/src/domain/entities/reading_visit.dart';

void main() {
  final addedAt = DateTime.utc(2026, 8, 1);

  ReaderDocument sample({
    String id = 'doc_1',
    String title = 'Sample',
    DateTime? lastOpenedAt,
    bool favorite = false,
  }) {
    return ReaderDocument(
      id: id,
      title: title,
      filePath: '/tmp/$id.pdf',
      sizeBytes: 2048,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt,
      isFavorite: favorite,
    );
  }

  group('ReaderDocument', () {
    test('defaults to LOCAL_ONLY privacy state', () {
      expect(sample().privacyState, DocumentPrivacyState.localOnly);
    });

    test('rejects negative sizes and non-positive page counts', () {
      expect(
        () => ReaderDocument(
          id: 'x',
          title: 't',
          filePath: '/x.pdf',
          sizeBytes: -1,
          addedAt: addedAt,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ReaderDocument(
          id: 'x',
          title: 't',
          filePath: '/x.pdf',
          sizeBytes: 10,
          addedAt: addedAt,
          pageCount: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('JSON round-trips all fields', () {
      final document = sample(lastOpenedAt: DateTime.utc(2026, 8, 10));
      final restored = ReaderDocument.fromJson(document.toJson());
      expect(restored, document);
    });

    test('fromJson tolerates absent optional fields', () {
      final restored = ReaderDocument.fromJson(sample().toJson());
      expect(restored.pageCount, isNull);
      expect(restored.lastOpenedAt, isNull);
      expect(restored.isFavorite, isFalse);
    });

    test('fromJson throws FormatException on malformed payload', () {
      expect(
        () => ReaderDocument.fromJson(const {'id': 'x'}),
        throwsFormatException,
      );
    });

    test('copyWith replaces only requested fields', () {
      final updated = sample().copyWith(title: 'Renamed', isFavorite: true);
      expect(updated.title, 'Renamed');
      expect(updated.isFavorite, isTrue);
      expect(updated.filePath, sample().filePath);
    });
  });

  group('ReadingPosition', () {
    test('clamps page numbers into the valid range', () {
      final low = ReadingPosition(
        documentId: 'd',
        pageNumber: 0,
        updatedAt: addedAt,
      );
      expect(low.pageNumber, 1);

      final high = ReadingPosition(
        documentId: 'd',
        pageNumber: 999,
        totalPages: 12,
        updatedAt: addedAt,
      );
      expect(high.pageNumber, 12);
    });

    test('JSON round-trips', () {
      final position = ReadingPosition(
        documentId: 'doc_1',
        pageNumber: 5,
        totalPages: 42,
        updatedAt: addedAt,
      );
      expect(ReadingPosition.fromJson(position.toJson()), position);
    });

    test('fromJson throws FormatException on malformed payload', () {
      expect(
        () => ReadingPosition.fromJson(const {'documentId': 'x'}),
        throwsFormatException,
      );
    });

    test('copyWith re-clamps against the new page count', () {
      final position = ReadingPosition(
        documentId: 'd',
        pageNumber: 10,
        totalPages: 20,
        updatedAt: addedAt,
      );
      expect(position.copyWith(totalPages: 5).pageNumber, 5);
    });
  });

  group('ReadingVisit', () {
    test('JSON round-trips', () {
      final visit = ReadingVisit(documentId: 'doc_1', visitedAt: addedAt);
      expect(ReadingVisit.fromJson(visit.toJson()), visit);
    });

    test('fromJson throws FormatException on malformed payload', () {
      expect(
        () => ReadingVisit.fromJson(const {'documentId': 42}),
        throwsFormatException,
      );
    });
  });
}
