import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';

void main() {
  group('UnifiedTextContext AI Adapter Tests', () {
    const docId = 'doc_constitution_ai';
    const docName = 'Constitution of India.pdf';

    test('converts native selection to AIReadingRequest for explain task', () {
      const snapshot = PdfTextSelectionSnapshot(
        text:
            'The Executive power of the Union shall be vested in the President.',
        fragments: [
          PdfSelectionFragment(
            pageNumber: 52,
            rect: NormalizedPageRect(
                left: 0.1, top: 0.2, right: 0.9, bottom: 0.25),
          ),
        ],
      );

      final context = UnifiedTextContext.fromNativeSnapshot(
        documentId: docId,
        documentName: docName,
        snapshot: snapshot,
      );

      final request = context.toAIReadingRequest(
        task: AIReadingTask.explain,
      );

      expect(request.task, AIReadingTask.explain);
      expect(request.text, snapshot.text);
      expect(request.documentId, docId);
      expect(request.documentName, docName);
      expect(request.pageNumber, 52);
      expect(request.contextScope, AIContextScope.selection);
    });

    test('converts OCR selection to AIReadingRequest for summarize task', () {
      const ocrSelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 12,
        selectedText:
            'All citizens shall have the right to freedom of speech and expression.',
        startOffset: 0,
        endOffset: 70,
        selectedTokenIndices: [0, 1, 2, 3, 4],
        boundingBoxes: [
          NormalizedPageRect(left: 0.15, top: 0.3, right: 0.85, bottom: 0.38),
        ],
      );

      final context = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: docName,
        confidence: 0.97,
      );

      final request = context.toAIReadingRequest(
        task: AIReadingTask.summarize,
        summaryLength: AISummaryLength.short,
      );

      expect(request.task, AIReadingTask.summarize);
      expect(request.text, ocrSelection.selectedText);
      expect(request.documentId, docId);
      expect(request.documentName, docName);
      expect(request.pageNumber, 12);
      expect(request.summaryLength, AISummaryLength.short);
    });

    test('converts OCR selection to AIReadingRequest for Ask AI question task',
        () {
      const ocrSelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 21,
        selectedText:
            'No person shall be deprived of his life or personal liberty except according to procedure established by law.',
        startOffset: 0,
        endOffset: 111,
        selectedTokenIndices: [0, 1, 2],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.4, right: 0.9, bottom: 0.48),
        ],
      );

      final context = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: docName,
      );

      final request = context.toAIReadingRequest(
        task: AIReadingTask.askQuestion,
        userQuestion: 'What does procedure established by law mean?',
      );

      expect(request.task, AIReadingTask.askQuestion);
      expect(request.text, ocrSelection.selectedText);
      expect(
          request.userQuestion, 'What does procedure established by law mean?');
      expect(request.documentId, docId);
      expect(request.pageNumber, 21);
    });

    test('converts selection to simplify and key points tasks accurately', () {
      final context = UnifiedTextContext(
        documentId: docId,
        documentName: docName,
        pageNumber: 3,
        selectedText:
            'Notwithstanding anything in this Constitution, Parliament may...',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final simplifyReq = context.toAIReadingRequest(
        task: AIReadingTask.simplify,
        simplifyLevel: AISimplifyLevel.verySimple,
      );
      expect(simplifyReq.task, AIReadingTask.simplify);
      expect(simplifyReq.simplifyLevel, AISimplifyLevel.verySimple);

      final keyPointsReq = context.toAIReadingRequest(
        task: AIReadingTask.keyPoints,
      );
      expect(keyPointsReq.task, AIReadingTask.keyPoints);
    });
  });
}
