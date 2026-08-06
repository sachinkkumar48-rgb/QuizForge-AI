import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Ingestion Validation Suite', () {
    late KnowledgeSource testSource;

    setUp(() {
      testSource = const KnowledgeSource(
        sourceId: 'VAL_SRC',
        title: 'Validation Source',
      );
    });

    test('ChecksumValidator verifies SHA-256 integrity', () async {
      final validDoc = KnowledgeDocument.create(
        documentId: 'DOC-VAL-1',
        source: testSource,
        type: KnowledgeDocumentType.constitution,
        title: 'Article 14',
        content: 'Equality before law',
        publicationDate: DateTime.now(),
      );

      final validator = ChecksumValidator();
      final resValid = await validator.validate(validDoc);
      expect(resValid.isValid, isTrue);

      final tamperedDoc = validDoc.copyWith(checksum: '1234567890abcdef');
      final resTampered = await validator.validate(tamperedDoc);
      expect(resTampered.isValid, isFalse);
      expect(resTampered.issues.first.code, equals('CHECKSUM_MISMATCH'));
    });

    test('DuplicateDocumentValidator flags duplicate document IDs & checksums', () async {
      final doc1 = KnowledgeDocument.create(
        documentId: 'DOC-DUP-1',
        source: testSource,
        type: KnowledgeDocumentType.gazetteNotification,
        title: 'Notification 1',
        content: 'Gazette Content A',
        publicationDate: DateTime.now(),
      );

      final dupValidator = DuplicateDocumentValidator();
      final res1 = await dupValidator.validate(doc1);
      expect(res1.isValid, isTrue);

      dupValidator.registerDocument(doc1);

      final resDupId = await dupValidator.validate(doc1.copyWith(content: 'Different content to alter hash'));
      expect(resDupId.isValid, isFalse);
      expect(resDupId.issues.any((i) => i.code == 'DUPLICATE_DOCUMENT_ID'), isTrue);
    });

    test('MetadataValidator flags missing required fields', () async {
      final invalidDoc = KnowledgeDocument.create(
        documentId: 'DOC-META-1',
        source: const KnowledgeSource(sourceId: '', title: ''),
        type: KnowledgeDocumentType.generic,
        title: '   ',
        content: 'Content here',
        publicationDate: DateTime.now(),
      );

      final metaVal = MetadataValidator();
      final res = await metaVal.validate(invalidDoc);
      expect(res.isValid, isFalse);
      expect(res.issues.any((i) => i.code == 'MISSING_TITLE'), isTrue);
      expect(res.issues.any((i) => i.code == 'MISSING_SOURCE_ID'), isTrue);
    });

    test('VersionValidator checks semver format', () async {
      final doc = KnowledgeDocument.create(
        documentId: 'DOC-VER-1',
        source: testSource,
        type: KnowledgeDocumentType.pibRelease,
        title: 'PIB Title',
        content: 'PIB Body Text',
        publicationDate: DateTime.now(),
        version: 'invalid_version_str',
      );

      final verVal = VersionValidator();
      final res = await verVal.validate(doc);
      expect(res.isValid, isFalse);
      expect(res.issues.first.code, equals('INVALID_VERSION_FORMAT'));
    });

    test('CompositeIngestionValidator aggregates all validation rules', () async {
      final validDoc = KnowledgeDocument.create(
        documentId: 'DOC-COMP-1',
        source: testSource,
        type: KnowledgeDocumentType.unionBudget,
        title: 'Union Budget 2024-25',
        content: 'Key highlights of the Union Budget for economic growth.',
        publicationDate: DateTime.now(),
      );

      final composite = CompositeIngestionValidator();
      final res = await composite.validate(validDoc);
      expect(res.isValid, isTrue);
    });
  });
}
