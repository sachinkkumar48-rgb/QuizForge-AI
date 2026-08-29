import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/source_reference.dart';

void main() {
  group('SourceReference Entity Tests (TITAN-KO-025.0 P25)', () {
    test('1. Valid construction with full provenance details', () {
      final ref = SourceReference(
        sourceId: 'doc_const_art21',
        sourceType: SourceReferenceType.constitution,
        referenceIdentifier: 'Article 21, Constitution of India',
        pageNumber: 14,
        excerptText:
            'No person shall be deprived of his life or personal liberty except according to procedure established by law.',
        documentUri: 'titan://reader/doc_const_art21#page=14',
        metadata: {'amendment': '44th CAA'},
      );

      expect(ref.sourceId, equals('doc_const_art21'));
      expect(ref.sourceType, equals(SourceReferenceType.constitution));
      expect(
          ref.referenceIdentifier, equals('Article 21, Constitution of India'));
      expect(ref.pageNumber, equals(14));
      expect(ref.hasExcerpt, isTrue);
      expect(ref.hasDocumentUri, isTrue);
      expect(ref.metadata['amendment'], equals('44th CAA'));
    });

    test('2. Rejects empty sourceId', () {
      expect(
        () => SourceReference(
          sourceId: '   ',
          sourceType: SourceReferenceType.statute,
          referenceIdentifier: 'Section 300, Indian Penal Code',
        ),
        throwsArgumentError,
      );
    });

    test('3. Rejects empty referenceIdentifier', () {
      expect(
        () => SourceReference(
          sourceId: 'doc_ipc_300',
          sourceType: SourceReferenceType.statute,
          referenceIdentifier: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('4. Rejects pageNumber < 1', () {
      expect(
        () => SourceReference(
          sourceId: 'doc_ipc_300',
          sourceType: SourceReferenceType.statute,
          referenceIdentifier: 'Section 300, Indian Penal Code',
          pageNumber: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceReference(
          sourceId: 'doc_ipc_300',
          sourceType: SourceReferenceType.statute,
          referenceIdentifier: 'Section 300, Indian Penal Code',
          pageNumber: -2,
        ),
        throwsArgumentError,
      );
    });

    test('5. JSON roundtrip preserves all fields', () {
      final ref = SourceReference(
        sourceId: 'case_maneka_gandhi',
        sourceType: SourceReferenceType.caseLaw,
        referenceIdentifier: 'Maneka Gandhi v. Union of India (1978) 1 SCC 248',
        pageNumber: 280,
        excerptText:
            'Procedure established by law must be just, fair and reasonable.',
        documentUri: 'titan://reader/case_maneka_gandhi#p=280',
        metadata: {'bench': '7 judges'},
      );

      final json = ref.toJson();
      final restored = SourceReference.fromJson(json);

      expect(restored, equals(ref));
      expect(restored.hashCode, equals(ref.hashCode));
      expect(restored.excerptText, equals(ref.excerptText));
      expect(restored.metadata['bench'], equals('7 judges'));
    });
  });
}
