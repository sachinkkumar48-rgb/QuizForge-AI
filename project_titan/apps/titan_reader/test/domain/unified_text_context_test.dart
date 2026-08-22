import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';

void main() {
  group('UnifiedTextContext Domain & Adapter Tests', () {
    const docId = 'doc_constitution';
    const docName = 'Constitution of India.pdf';

    test('constructs UnifiedTextContext with direct fields accurately', () {
      final now = DateTime.now();
      final context = UnifiedTextContext(
        documentId: docId,
        documentName: docName,
        pageNumber: 3,
        selectedText: 'Sovereignty',
        source: TextProvenance.nativePdf,
        selectionBounds: const [
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.4, bottom: 0.25),
        ],
        languageCode: 'en',
        confidence: 1.0,
        timestamp: now,
      );

      expect(context.documentId, docId);
      expect(context.documentName, docName);
      expect(context.pageNumber, 3);
      expect(context.selectedText, 'Sovereignty');
      expect(context.source, TextProvenance.nativePdf);
      expect(context.isNative, isTrue);
      expect(context.isOcr, isFalse);
      expect(context.isSingleWord, isTrue);
      expect(context.normalizedWord, 'sovereignty');
      expect(context.characterCount, 11);
      expect(context.wordCount, 1);
      expect(context.confidence, 1.0);
    });

    test('adapts native PdfTextSelectionSnapshot cleanly via factory', () {
      const snapshot = PdfTextSelectionSnapshot(
        text: 'Fundamental Rights',
        fragments: [
          PdfSelectionFragment(
            pageNumber: 5,
            rect: NormalizedPageRect(
                left: 0.1, top: 0.3, right: 0.4, bottom: 0.35),
          ),
          PdfSelectionFragment(
            pageNumber: 5,
            rect: NormalizedPageRect(
                left: 0.42, top: 0.3, right: 0.6, bottom: 0.35),
          ),
        ],
      );

      final context = UnifiedTextContext.fromNativeSnapshot(
        documentId: docId,
        documentName: docName,
        snapshot: snapshot,
      );

      expect(context.documentId, docId);
      expect(context.pageNumber, 5);
      expect(context.selectedText, 'Fundamental Rights');
      expect(context.source, TextProvenance.nativePdf);
      expect(context.isNative, isTrue);
      expect(context.isSingleWord, isFalse);
      expect(context.wordCount, 2);
      expect(context.selectionBounds.length, 2);
      expect(context.confidence, 1.0);
    });

    test('adapts OcrTextSelection cleanly via factory', () {
      const ocrSelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 8,
        selectedText: 'Preamble',
        startOffset: 0,
        endOffset: 8,
        selectedTokenIndices: [0],
        boundingBoxes: [
          NormalizedPageRect(left: 0.2, top: 0.1, right: 0.5, bottom: 0.18),
        ],
      );

      final context = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: docName,
        confidence: 0.96,
      );

      expect(context.documentId, docId);
      expect(context.documentName, docName);
      expect(context.pageNumber, 8);
      expect(context.selectedText, 'Preamble');
      expect(context.source, TextProvenance.ocr);
      expect(context.isOcr, isTrue);
      expect(context.isSingleWord, isTrue);
      expect(context.normalizedWord, 'preamble');
      expect(context.confidence, 0.96);
      expect(context.selectionBounds.length, 1);
    });

    test(
        'converts UnifiedTextContext back to standard PdfTextSelectionSnapshot',
        () {
      final context = UnifiedTextContext(
        documentId: docId,
        pageNumber: 2,
        selectedText: 'Democracy',
        source: TextProvenance.ocr,
        selectionBounds: const [
          NormalizedPageRect(left: 0.3, top: 0.4, right: 0.6, bottom: 0.45),
        ],
        timestamp: DateTime.now(),
      );

      final snapshot = context.toSnapshot();
      expect(snapshot.text, 'Democracy');
      expect(snapshot.fragments.length, 1);
      expect(snapshot.fragments.first.pageNumber, 2);
      expect(snapshot.fragments.first.rect.left, 0.3);
    });

    test('validates stale context comparison via isSameContext', () {
      final now = DateTime.now();
      final ctx1 = UnifiedTextContext(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'Liberty',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: now,
      );

      final ctx1Clone = UnifiedTextContext(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'Liberty',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: now.add(const Duration(seconds: 1)),
      );

      final ctxDifferentDoc = UnifiedTextContext(
        documentId: 'doc_2',
        pageNumber: 1,
        selectedText: 'Liberty',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: now,
      );

      final ctxDifferentPage = UnifiedTextContext(
        documentId: 'doc_1',
        pageNumber: 2,
        selectedText: 'Liberty',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: now,
      );

      final ctxDifferentText = UnifiedTextContext(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'Fraternity',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: now,
      );

      expect(ctx1.isSameContext(ctx1Clone), isTrue);
      expect(ctx1.isSameContext(ctxDifferentDoc), isFalse);
      expect(ctx1.isSameContext(ctxDifferentPage), isFalse);
      expect(ctx1.isSameContext(ctxDifferentText), isFalse);
      expect(ctx1.isSameContext(null), isFalse);
    });

    test('serializes and deserializes UnifiedTextContext to JSON cleanly', () {
      final now = DateTime.utc(2026, 8, 22, 12, 0, 0);
      final context = UnifiedTextContext(
        documentId: 'doc_json',
        documentName: 'TestDoc.pdf',
        pageNumber: 4,
        selectedText: 'Judiciary',
        source: TextProvenance.ocr,
        selectionBounds: const [
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.5, bottom: 0.25),
        ],
        languageCode: 'en',
        confidence: 0.93,
        timestamp: now,
      );

      final json = context.toJson();
      final deserialized = UnifiedTextContext.fromJson(json);

      expect(deserialized.documentId, 'doc_json');
      expect(deserialized.documentName, 'TestDoc.pdf');
      expect(deserialized.pageNumber, 4);
      expect(deserialized.selectedText, 'Judiciary');
      expect(deserialized.source, TextProvenance.ocr);
      expect(deserialized.languageCode, 'en');
      expect(deserialized.confidence, 0.93);
      expect(deserialized.selectionBounds.length, 1);
    });
  });
}
