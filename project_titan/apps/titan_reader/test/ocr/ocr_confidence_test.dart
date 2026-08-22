import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';

void main() {
  group('OcrConfidence Domain Value Object Tests', () {
    test('clamps values within [0.0, 1.0]', () {
      const negative = OcrConfidence(-0.5);
      expect(negative.value, 0.0);

      const excessive = OcrConfidence(1.75);
      expect(excessive.value, 1.0);

      const normal = OcrConfidence(0.88);
      expect(normal.value, 0.88);
    });

    test('categorizes rating levels accurately', () {
      const high = OcrConfidence(0.95);
      expect(high.level, OcrConfidenceLevel.high);

      const highBoundary = OcrConfidence(0.85);
      expect(highBoundary.level, OcrConfidenceLevel.high);

      const medium = OcrConfidence(0.72);
      expect(medium.level, OcrConfidenceLevel.medium);

      const mediumBoundary = OcrConfidence(0.60);
      expect(mediumBoundary.level, OcrConfidenceLevel.medium);

      const low = OcrConfidence(0.45);
      expect(low.level, OcrConfidenceLevel.low);
    });

    test('formats percentage string and supports JSON roundtrip', () {
      const conf = OcrConfidence(0.924);
      expect(conf.percentageString, '92.4%');

      final json = conf.toJson();
      final restored = OcrConfidence.fromJson(json);
      expect(restored, equals(conf));
    });

    test('implements Comparable and equality semantics', () {
      const c1 = OcrConfidence(0.5);
      const c2 = OcrConfidence(0.5000001);
      const c3 = OcrConfidence(0.8);

      expect(c1, equals(c2));
      expect(c1.compareTo(c3), isNegative);
      expect(c3.compareTo(c1), isPositive);
    });
  });
}
