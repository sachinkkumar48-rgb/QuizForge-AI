import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';

void main() {
  group('OcrTextRegion Domain Hierarchy Tests', () {
    test('OcrWord creates correctly, compares equality, and serializes to JSON',
        () {
      const bbox = NormalizedPageRect(
        left: 0.1,
        top: 0.2,
        right: 0.3,
        bottom: 0.25,
      );
      const word = OcrWord(
        text: 'Constitutional',
        boundingBox: bbox,
        confidence: OcrConfidence(0.96),
        wordIndex: 0,
      );

      expect(word.text, 'Constitutional');
      expect(word.boundingBox.left, 0.1);
      expect(word.confidence.level, OcrConfidenceLevel.high);

      final json = word.toJson();
      final restored = OcrWord.fromJson(json);
      expect(restored, equals(word));
    });

    test('OcrLine aggregates words, checks equality, and serializes to JSON',
        () {
      const w1 = OcrWord(
        text: 'Article',
        boundingBox: NormalizedPageRect(
          left: 0.1,
          top: 0.1,
          right: 0.2,
          bottom: 0.14,
        ),
        confidence: OcrConfidence(0.98),
        wordIndex: 0,
      );
      const w2 = OcrWord(
        text: '21',
        boundingBox: NormalizedPageRect(
          left: 0.22,
          top: 0.1,
          right: 0.28,
          bottom: 0.14,
        ),
        confidence: OcrConfidence(0.99),
        wordIndex: 1,
      );

      const line = OcrLine(
        text: 'Article 21',
        boundingBox: NormalizedPageRect(
          left: 0.1,
          top: 0.1,
          right: 0.28,
          bottom: 0.14,
        ),
        confidence: OcrConfidence(0.985),
        lineIndex: 0,
        words: [w1, w2],
      );

      expect(line.words.length, 2);
      expect(line.text, 'Article 21');

      final json = line.toJson();
      final restored = OcrLine.fromJson(json);
      expect(restored, equals(line));
    });

    test('OcrBlock aggregates lines, handles equality, and serializes to JSON',
        () {
      const line = OcrLine(
        text: 'Protection of life and personal liberty.',
        boundingBox: NormalizedPageRect(
          left: 0.1,
          top: 0.16,
          right: 0.8,
          bottom: 0.2,
        ),
        confidence: OcrConfidence(0.94),
        lineIndex: 0,
      );

      const block = OcrBlock(
        text: 'Protection of life and personal liberty.',
        boundingBox: NormalizedPageRect(
          left: 0.1,
          top: 0.16,
          right: 0.8,
          bottom: 0.2,
        ),
        confidence: OcrConfidence(0.94),
        blockIndex: 0,
        lines: [line],
      );

      expect(block.lines.length, 1);
      final json = block.toJson();
      final restored = OcrBlock.fromJson(json);
      expect(restored, equals(block));
    });
  });
}
