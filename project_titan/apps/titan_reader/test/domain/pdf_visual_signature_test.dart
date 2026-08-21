import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_visual_signature.dart';

void main() {
  group('PdfVisualSignature Domain', () {
    test('creates drawn signature and validates properly', () {
      final strokes = [
        [
          const PdfSignaturePoint(0.1, 0.2),
          const PdfSignaturePoint(0.3, 0.4),
        ],
      ];
      final sig = PdfVisualSignature.drawn(
        id: 'sig_1',
        name: 'My Signature',
        strokes: strokes,
        colorArgb: 0xFF000000,
      );

      expect(sig.id, 'sig_1');
      expect(sig.name, 'My Signature');
      expect(sig.type, PdfSignatureType.drawn);
      expect(sig.strokes.length, 1);
      expect(sig.strokes.first.length, 2);
      expect(sig.isValid, isTrue);
    });

    test('creates typed signature and validates properly', () {
      final sig = PdfVisualSignature.typed(
        id: 'sig_2',
        name: 'Formal Initial',
        text: 'Jane Doe',
        fontStyle: 'cursive',
      );

      expect(sig.type, PdfSignatureType.typed);
      expect(sig.typedText, 'Jane Doe');
      expect(sig.fontStyle, 'cursive');
      expect(sig.isValid, isTrue);
    });

    test('creates image signature and validates properly', () {
      final sig = PdfVisualSignature.image(
        id: 'sig_3',
        name: 'Stamp Logo',
        imageBase64:
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );

      expect(sig.type, PdfSignatureType.image);
      expect(sig.imageBase64.isNotEmpty, isTrue);
      expect(sig.isValid, isTrue);
    });

    test('validates invalid / empty data correctly', () {
      final emptyName = PdfVisualSignature.typed(
        id: 'sig_e1',
        name: '   ',
        text: 'Jane',
      );
      expect(emptyName.isValid, isFalse);

      final emptyStrokes = PdfVisualSignature.drawn(
        id: 'sig_e2',
        name: 'Drawn',
        strokes: const [],
      );
      expect(emptyStrokes.isValid, isFalse);

      final emptyText = PdfVisualSignature.typed(
        id: 'sig_e3',
        name: 'Typed',
        text: '',
      );
      expect(emptyText.isValid, isFalse);

      final emptyImage = PdfVisualSignature.image(
        id: 'sig_e4',
        name: 'Image',
        imageBase64: '   ',
      );
      expect(emptyImage.isValid, isFalse);
    });

    test('serializes and deserializes drawn signature to/from JSON roundtrip',
        () {
      final now = DateTime(2026, 8, 21, 12, 0);
      final sig = PdfVisualSignature(
        id: 'sig_json_1',
        name: 'CEO Sign',
        type: PdfSignatureType.drawn,
        strokes: const [
          [PdfSignaturePoint(0.12, 0.34), PdfSignaturePoint(0.56, 0.78)],
        ],
        colorArgb: 0xFF002244,
        createdAt: now,
        updatedAt: now,
      );

      final json = sig.toJson();
      final recovered = PdfVisualSignature.fromJson(json);

      expect(recovered.id, sig.id);
      expect(recovered.name, sig.name);
      expect(recovered.type, sig.type);
      expect(recovered.colorArgb, sig.colorArgb);
      expect(recovered.strokes.length, 1);
      expect(recovered.strokes.first.first.x, closeTo(0.12, 1e-3));
      expect(recovered.strokes.first.first.y, closeTo(0.34, 1e-3));
      expect(recovered, equals(sig));
    });

    test('copyWith updates fields correctly', () {
      final sig = PdfVisualSignature.typed(
        id: 'sig_c1',
        name: 'Initial',
        text: 'JD',
      );
      final updated =
          sig.copyWith(name: 'Full Signature', typedText: 'John Doe');

      expect(updated.id, 'sig_c1');
      expect(updated.name, 'Full Signature');
      expect(updated.typedText, 'John Doe');
      expect(sig.name, 'Initial');
    });
  });
}
