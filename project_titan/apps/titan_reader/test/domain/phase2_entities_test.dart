import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/reader_annotation.dart';
import 'package:titan_reader/src/domain/entities/reader_bookmark.dart';
import 'package:titan_reader/src/domain/entities/reader_note.dart';

void main() {
  group('NormalizedPageRect', () {
    test('scaleTo maps fractions to absolute page coordinates', () {
      const rect =
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.5, bottom: 0.3);
      final scaled = rect.scaleTo(600, 800);
      expect(scaled.left, closeTo(60, 1e-9));
      expect(scaled.top, closeTo(160, 1e-9));
      expect(scaled.right, closeTo(300, 1e-9));
      expect(scaled.bottom, closeTo(240, 1e-9));
    });

    test('scaleTo is proportional: stable across zoom and resize', () {
      const rect =
          NormalizedPageRect(left: 0.25, top: 0.25, right: 0.75, bottom: 0.5);
      final small = rect.scaleTo(300, 400);
      final zoomed = rect.scaleTo(600, 800);
      // Fractions of the page stay identical; only the page size scales.
      expect(small.width / 300, closeTo(zoomed.width / 600, 1e-9));
      expect(small.height / 400, closeTo(zoomed.height / 800, 1e-9));
      expect(small.left / 300, closeTo(zoomed.left / 600, 1e-9));
    });

    test('fromPageCoordinates clamps and normalizes edge ordering', () {
      final rect = NormalizedPageRect.fromPageCoordinates(
        left: 700, // beyond page width -> clamps to 1
        pdfTop: 0.6 * 1000,
        right: 0.2 * 600,
        pdfBottom: 0.2 * 1000, // inverted vs top -> must be reordered
        pageWidth: 600,
        pageHeight: 1000,
      );
      expect(rect.left, closeTo(0.2, 1e-9));
      expect(rect.right, closeTo(1.0, 1e-9));
      expect(rect.top, closeTo(0.2, 1e-9));
      expect(rect.bottom, closeTo(0.6, 1e-9));
    });

    test('JSON round-trip preserves geometry', () {
      const rect =
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.3, bottom: 0.4);
      expect(NormalizedPageRect.fromJson(rect.toJson()), rect);
    });

    test('fromJson rejects non-numeric fields', () {
      expect(
        () => NormalizedPageRect.fromJson(
            const {'left': 'x', 'top': 0, 'right': 1, 'bottom': 1}),
        throwsFormatException,
      );
    });
  });

  group('ReaderAnnotation', () {
    ReaderAnnotation annotation({
      ReaderAnnotationType type = ReaderAnnotationType.highlight,
      ReaderAnnotationColor color = ReaderAnnotationColor.yellow,
    }) {
      final now = DateTime.utc(2026, 8, 10);
      return ReaderAnnotation(
        id: 'ann_1',
        documentId: 'doc_1',
        pageNumber: 3,
        type: type,
        color: color,
        selectedText: 'separation of powers',
        rects: const [
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.6, bottom: 0.25),
          NormalizedPageRect(left: 0.1, top: 0.3, right: 0.4, bottom: 0.35),
        ],
        createdAt: now,
        updatedAt: now,
      );
    }

    test('rects are stored unmodifiable', () {
      expect(
          () => annotation().rects.add(const NormalizedPageRect(
                left: 0,
                top: 0,
                right: 1,
                bottom: 1,
              )),
          throwsUnsupportedError);
    });

    test('JSON round-trip preserves every field', () {
      final original = annotation(
        type: ReaderAnnotationType.strikethrough,
        color: ReaderAnnotationColor.pink,
      );
      final restored = ReaderAnnotation.fromJson(original.toJson());
      expect(restored, original);
      expect(restored.type, ReaderAnnotationType.strikethrough);
      expect(restored.color, ReaderAnnotationColor.pink);
      expect(restored.rects, hasLength(2));
    });

    test('unknown wire values fall back to defaults', () {
      final json = annotation().toJson();
      json['type'] = 'scribble';
      json['color'] = 'rainbow';
      final restored = ReaderAnnotation.fromJson(json);
      expect(restored.type, ReaderAnnotationType.highlight);
      expect(restored.color, ReaderAnnotationColor.yellow);
    });

    test('missing required fields throw FormatException', () {
      final json = annotation().toJson()..remove('rects');
      expect(() => ReaderAnnotation.fromJson(json), throwsFormatException);
    });

    test('copyWith replaces only requested fields', () {
      final original = annotation();
      final changed = original.copyWith(
        color: ReaderAnnotationColor.blue,
        updatedAt: DateTime.utc(2026, 8, 11),
      );
      expect(changed.id, original.id);
      expect(changed.rects, original.rects);
      expect(changed.color, ReaderAnnotationColor.blue);
      expect(changed.updatedAt, DateTime.utc(2026, 8, 11));
      expect(changed.createdAt, original.createdAt);
    });
  });

  group('ReaderBookmark', () {
    ReaderBookmark bookmark({String title = 'Chapter 2'}) => ReaderBookmark(
          id: 'bm_1',
          documentId: 'doc_1',
          pageNumber: 12,
          title: title,
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 1),
        );

    test('JSON round-trip', () {
      expect(ReaderBookmark.fromJson(bookmark().toJson()), bookmark());
    });

    test('copyWith updates title and page', () {
      final updated = bookmark().copyWith(
        title: 'Renamed',
        pageNumber: 13,
        updatedAt: DateTime.utc(2026, 8, 2),
      );
      expect(updated.title, 'Renamed');
      expect(updated.pageNumber, 13);
      expect(updated.documentId, 'doc_1');
    });

    test('page number must be >= 1', () {
      expect(
        () => ReaderBookmark(
          id: 'x',
          documentId: 'd',
          pageNumber: 0,
          title: 't',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        throwsAssertionError,
      );
    });
  });

  group('ReaderOutlineEntry', () {
    test('carries engine-agnostic path and optional page', () {
      const entry = ReaderOutlineEntry(
        title: 'Part I',
        path: '0/2/1',
        pageNumber: 5,
      );
      expect(entry.children, isEmpty);
      expect(entry.path, '0/2/1');
    });
  });

  group('ReaderNote', () {
    ReaderNote note({
      String title = 'Key idea',
      String content = 'Remember this',
      String? selectedText,
    }) =>
        ReaderNote(
          id: 'note_1',
          documentId: 'doc_1',
          pageNumber: 4,
          title: title,
          content: content,
          selectedText: selectedText,
          createdAt: DateTime.utc(2026, 8, 3),
          updatedAt: DateTime.utc(2026, 8, 3),
        );

    test('JSON round-trip including null references', () {
      expect(ReaderNote.fromJson(note().toJson()), note());
      final withRef = note(selectedText: 'quoted text');
      final restored = ReaderNote.fromJson(withRef.toJson());
      expect(restored.selectedText, 'quoted text');
    });

    test('matches searches title, content and selectedText', () {
      final subject = note(
        title: 'Fundamental Rights',
        content: 'Article 14 analysis',
        selectedText: 'equality before law',
      );
      expect(subject.matches('rights'), isTrue);
      expect(subject.matches('ARTICLE 14'), isTrue);
      expect(subject.matches('equality'), isTrue);
      expect(subject.matches('unrelated'), isFalse);
      expect(subject.matches('   '), isFalse);
    });

    test('copyWith updates editable fields only', () {
      final updated = note().copyWith(
        title: 'New title',
        content: 'New content',
        updatedAt: DateTime.utc(2026, 8, 9),
      );
      expect(updated.title, 'New title');
      expect(updated.content, 'New content');
      expect(updated.pageNumber, 4);
      expect(updated.createdAt, DateTime.utc(2026, 8, 3));
    });

    test('notes survive independently of annotation references', () {
      final linked = ReaderNote(
        id: 'n2',
        documentId: 'doc_1',
        pageNumber: 2,
        title: 'Linked',
        content: 'body',
        annotationId: 'ann_gone',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      // Deleting the annotation never invalidates the note itself.
      expect(ReaderNote.fromJson(linked.toJson()).annotationId, 'ann_gone');
      expect(linked.content, 'body');
    });
  });
}
