import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/providers/ocr_providers.dart';

void main() {
  group('OCR Text Normalization & Search Tests', () {
    const docId = 'doc_constitution';

    final sampleOcrResult = OcrResult.success(
      pageNumber: 1,
      blocks: const [
        OcrBlock(
          text: 'Indian Polity and Constitution',
          boundingBox: NormalizedPageRect(
            left: 0.1,
            top: 0.1,
            right: 0.9,
            bottom: 0.2,
          ),
          confidence: OcrConfidence(0.95),
          lines: [
            OcrLine(
              text: 'Indian Polity and Constitution',
              boundingBox: NormalizedPageRect(
                left: 0.1,
                top: 0.1,
                right: 0.9,
                bottom: 0.2,
              ),
              confidence: OcrConfidence(0.95),
              words: [
                OcrWord(
                  text: 'Indian',
                  boundingBox: NormalizedPageRect(
                    left: 0.1,
                    top: 0.1,
                    right: 0.3,
                    bottom: 0.2,
                  ),
                  confidence: OcrConfidence(0.98),
                  wordIndex: 0,
                ),
                OcrWord(
                  text: 'Polity',
                  boundingBox: NormalizedPageRect(
                    left: 0.32,
                    top: 0.1,
                    right: 0.5,
                    bottom: 0.2,
                  ),
                  confidence: OcrConfidence(0.95),
                  wordIndex: 1,
                ),
                OcrWord(
                  text: 'and',
                  boundingBox: NormalizedPageRect(
                    left: 0.52,
                    top: 0.1,
                    right: 0.6,
                    bottom: 0.2,
                  ),
                  confidence: OcrConfidence(0.99),
                  wordIndex: 2,
                ),
                OcrWord(
                  text: 'Constitution',
                  boundingBox: NormalizedPageRect(
                    left: 0.62,
                    top: 0.1,
                    right: 0.9,
                    bottom: 0.2,
                  ),
                  confidence: OcrConfidence(0.92),
                  wordIndex: 3,
                ),
              ],
            ),
          ],
        ),
        OcrBlock(
          text: 'Fundamental Rights are guaranteed in Part III.',
          blockIndex: 1,
          boundingBox: NormalizedPageRect(
            left: 0.1,
            top: 0.3,
            right: 0.9,
            bottom: 0.45,
          ),
          confidence: OcrConfidence(0.90),
          lines: [
            OcrLine(
              text: 'Fundamental Rights are guaranteed in Part III.',
              boundingBox: NormalizedPageRect(
                left: 0.1,
                top: 0.3,
                right: 0.9,
                bottom: 0.45,
              ),
              confidence: OcrConfidence(0.90),
              words: [
                OcrWord(
                  text: 'Fundamental',
                  boundingBox: NormalizedPageRect(
                    left: 0.1,
                    top: 0.3,
                    right: 0.35,
                    bottom: 0.45,
                  ),
                  confidence: OcrConfidence(0.94),
                  wordIndex: 4,
                ),
                OcrWord(
                  text: 'Rights',
                  boundingBox: NormalizedPageRect(
                    left: 0.37,
                    top: 0.3,
                    right: 0.5,
                    bottom: 0.45,
                  ),
                  confidence: OcrConfidence(0.96),
                  wordIndex: 5,
                ),
                OcrWord(
                  text: 'are',
                  boundingBox: NormalizedPageRect(
                    left: 0.52,
                    top: 0.3,
                    right: 0.58,
                    bottom: 0.45,
                  ),
                  confidence: OcrConfidence(0.99),
                  wordIndex: 6,
                ),
                OcrWord(
                  text: 'guaranteed',
                  boundingBox: NormalizedPageRect(
                    left: 0.60,
                    top: 0.3,
                    right: 0.78,
                    bottom: 0.45,
                  ),
                  confidence: OcrConfidence(0.88),
                  wordIndex: 7,
                ),
                OcrWord(
                  text: 'in',
                  boundingBox: NormalizedPageRect(
                    left: 0.80,
                    top: 0.3,
                    right: 0.84,
                    bottom: 0.45,
                  ),
                  confidence: OcrConfidence(0.99),
                  wordIndex: 8,
                ),
                OcrWord(
                  text: 'Part',
                  boundingBox: NormalizedPageRect(
                    left: 0.85,
                    top: 0.3,
                    right: 0.90,
                    bottom: 0.45,
                  ),
                  confidence: OcrConfidence(0.95),
                  wordIndex: 9,
                ),
                OcrWord(
                  text: 'III.',
                  boundingBox: NormalizedPageRect(
                    left: 0.91,
                    top: 0.3,
                    right: 0.96,
                    bottom: 0.45,
                  ),
                  confidence: OcrConfidence(0.90),
                  wordIndex: 10,
                ),
              ],
            ),
          ],
        ),
      ],
      processingDurationMs: 120,
      engineName: 'MockEngine',
      modelIdentifier: 'test-model',
    );

    test('builds NormalizedOcrPageText with linear offsets and token mapping',
        () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleOcrResult,
      );

      expect(normText.documentId, docId);
      expect(normText.pageNumber, 1);
      expect(normText.tokens.length, 11);
      expect(normText.fullText, contains('Indian Polity and Constitution'));
      expect(normText.fullText,
          contains('Fundamental Rights are guaranteed in Part III.'));

      // Check first token offsets
      final firstToken = normText.tokens.first;
      expect(firstToken.text, 'Indian');
      expect(firstToken.startOffset, 0);
      expect(firstToken.endOffset, 6);
      expect(normText.fullText.substring(0, 6), 'Indian');
    });

    test(
        'performs case-insensitive substring search accurately across various sub-tokens',
        () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleOcrResult,
      );

      // 1. "Constitution" (Exact case full word)
      final match1 = normText.search('Constitution', caseSensitive: false);
      expect(match1.length, 1);
      expect(match1.first.matchedText, 'Constitution');

      // 2. "constitution" (Lowercase full word)
      final match2 = normText.search('constitution', caseSensitive: false);
      expect(match2.length, 1);
      expect(match2.first.matchedText, 'Constitution');

      // 3. "tution" (Substring / partial word)
      final match3 = normText.search('tution', caseSensitive: false);
      expect(match3.length, 1);
      expect(match3.first.matchedText, 'tution');
      expect(match3.first.boundingBoxes.length, 1);

      // 4. "India" (Substring inside "Indian")
      final match4 = normText.search('India', caseSensitive: false);
      expect(match4.length, 1);
      expect(match4.first.matchedText, 'India');

      // 5. "india" (Case-insensitive substring inside "Indian")
      final match5 = normText.search('india', caseSensitive: false);
      expect(match5.length, 1);
      expect(match5.first.matchedText, 'India');
    });

    test('respects case sensitivity when requested', () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleOcrResult,
      );

      final matchLower = normText.search('constitution', caseSensitive: true);
      expect(matchLower, isEmpty);

      final matchUpper = normText.search('Constitution', caseSensitive: true);
      expect(matchUpper.length, 1);
      expect(matchUpper.first.matchedText, 'Constitution');
    });

    test('handles multi-word search spanning multiple OCR token regions', () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleOcrResult,
      );

      final matches = normText.search('Fundamental Rights');
      expect(matches.length, 1);

      final match = matches.first;
      expect(match.matchedText, 'Fundamental Rights');
      expect(match.boundingBoxes.length, 2); // 'Fundamental' and 'Rights'
      expect(match.snippet, contains('Fundamental Rights'));
    });

    test('supports whole word matching', () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleOcrResult,
      );

      final partialMatch = normText.search('Right', wholeWord: false);
      expect(partialMatch.length, 1);

      final wholeWordMatch = normText.search('Right', wholeWord: true);
      expect(wholeWordMatch, isEmpty);

      final fullWordMatch = normText.search('Rights', wholeWord: true);
      expect(fullWordMatch.length, 1);
    });

    test('returns empty results on empty or whitespace query', () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleOcrResult,
      );

      expect(normText.search(''), isEmpty);
      expect(normText.search('   '), isEmpty);
    });

    test('converts OcrSearchMatch to standard PdfSearchMatch cleanly', () {
      const match = OcrSearchMatch(
        index: 0,
        documentId: 'doc_1',
        pageNumber: 3,
        matchedText: 'TITAN',
        snippet: '…Project TITAN Reader…',
        startOffset: 8,
        endOffset: 13,
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.1, right: 0.3, bottom: 0.2),
        ],
        confidence: 0.97,
      );

      final pdfMatch = match.toPdfSearchMatch(5);
      expect(pdfMatch.index, 5);
      expect(pdfMatch.pageNumber, 3);
      expect(pdfMatch.snippet, '…Project TITAN Reader…');
    });

    test('serializes and deserializes OcrSearchMatch to JSON cleanly', () {
      const match = OcrSearchMatch(
        index: 2,
        documentId: 'doc_json',
        pageNumber: 4,
        matchedText: 'Article 21',
        snippet: '…Protection of Life under Article 21…',
        startOffset: 25,
        endOffset: 35,
        boundingBoxes: [
          NormalizedPageRect(left: 0.2, top: 0.4, right: 0.5, bottom: 0.48),
        ],
        confidence: 0.94,
      );

      final json = match.toJson();
      final deserialized = OcrSearchMatch.fromJson(json);

      expect(deserialized.index, 2);
      expect(deserialized.documentId, 'doc_json');
      expect(deserialized.pageNumber, 4);
      expect(deserialized.matchedText, 'Article 21');
      expect(deserialized.confidence, 0.94);
    });

    test(
        'UnifiedSearchCoexistence merges native and OCR matches with deduplication',
        () {
      const nativeMatches = [
        PdfSearchMatch(
            index: 0, pageNumber: 1, snippet: 'Indian Polity and Constitution'),
        PdfSearchMatch(
            index: 1, pageNumber: 2, snippet: 'Preamble of the Constitution'),
      ];

      const ocrMatches = [
        OcrSearchMatch(
          index: 0,
          documentId: docId,
          pageNumber: 1,
          matchedText: 'Constitution',
          snippet:
              'Indian Polity and Constitution', // Duplicate of native match
          startOffset: 18,
          endOffset: 30,
          boundingBoxes: [],
          confidence: 0.95,
        ),
        OcrSearchMatch(
          index: 1,
          documentId: docId,
          pageNumber: 3, // Scanned page without native text
          matchedText: 'Constitution',
          snippet: 'Directive Principles of State Policy',
          startOffset: 0,
          endOffset: 12,
          boundingBoxes: [],
          confidence: 0.92,
        ),
      ];

      final unified = UnifiedSearchCoexistence.mergeMatches(
        nativeMatches: nativeMatches,
        ocrMatches: ocrMatches,
      );

      // Page 1 duplicate OCR snippet should be filtered; Page 3 OCR snippet included
      expect(unified.length, 3);
      expect(unified[0].pageNumber, 1);
      expect(unified[1].pageNumber, 2);
      expect(unified[2].pageNumber, 3);
      expect(unified[2].snippet, 'Directive Principles of State Policy');
      expect(unified[2].index, 2);
    });
  });
}
