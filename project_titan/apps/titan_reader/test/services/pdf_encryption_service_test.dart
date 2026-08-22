import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_encryption_options.dart';
import 'package:titan_reader/src/domain/pdf_manipulation_errors.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/services/pdf_encryption_service.dart';

void main() {
  late Directory tempDir;
  late File samplePdf;
  late PdfEncryptionService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_encrypt_test_');
    samplePdf = File('${tempDir.path}/sample_original.pdf');

    // Create a valid 2-page test PDF
    final ast = _createSamplePdf(pageCount: 2);
    final writer = PdfWriter(ast);
    await samplePdf.writeAsBytes(writer.writeBytes());

    service = const PdfEncryptionService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfEncryptionService Unit & Pipeline Tests', () {
    test('successfully encrypts PDF with AES-128 and preserves original file',
        () async {
      final originalBytes = await samplePdf.readAsBytes();
      final targetPath = '${tempDir.path}/sample_protected_aes.pdf';

      const config = PdfEncryptionConfig(
        userPassword: 'openPass123',
        ownerPassword: 'adminPass123',
        algorithm: PdfEncryptionAlgorithm.aes128,
        permissions: PdfPermissions(
          allowPrinting: true,
          allowModifying: false,
          allowCopying: false,
        ),
      );

      final result = await service.encryptPdfFile(
        sourceFilePath: samplePdf.path,
        targetFilePath: targetPath,
        config: config,
      );

      expect(result.isSuccess, isTrue);
      expect(result.outputPath, targetPath);
      expect(result.algorithm, PdfEncryptionAlgorithm.aes128);

      // Verify original file is 100% untouched
      final afterOriginalBytes = await samplePdf.readAsBytes();
      expect(afterOriginalBytes, equals(originalBytes));

      // Verify target file exists and has content
      final targetFile = File(targetPath);
      expect(await targetFile.exists(), isTrue);
      final targetBytes = await targetFile.readAsBytes();
      expect(targetBytes.length, greaterThan(100));

      // Verify encrypted PDF contains /Encrypt in trailer
      final targetStr = String.fromCharCodes(targetBytes);
      expect(targetStr, contains('/Encrypt'));
      expect(targetStr, contains('/Filter /Standard'));
      expect(targetStr, contains('/V 4'));
      expect(targetStr, contains('/R 4'));

      // Verify PdfParser recognizes the document as encrypted
      expect(
        () => PdfParser(targetBytes).parse(),
        throwsA(isA<PdfUnsupportedDocumentException>()),
      );
    });

    test('successfully encrypts PDF with RC4-128', () async {
      final targetPath = '${tempDir.path}/sample_protected_rc4.pdf';

      const config = PdfEncryptionConfig(
        userPassword: 'myRc4Password',
        algorithm: PdfEncryptionAlgorithm.rc4_128,
      );

      final result = await service.encryptPdfFile(
        sourceFilePath: samplePdf.path,
        targetFilePath: targetPath,
        config: config,
      );

      expect(result.isSuccess, isTrue);
      final targetBytes = await File(targetPath).readAsBytes();
      final targetStr = String.fromCharCodes(targetBytes);
      expect(targetStr, contains('/Encrypt'));
      expect(targetStr, contains('/V 2'));
      expect(targetStr, contains('/R 3'));
    });

    test('rejects empty passwords when protection is requested', () async {
      final targetPath = '${tempDir.path}/sample_out.pdf';
      const config = PdfEncryptionConfig(userPassword: '', ownerPassword: '');

      final result = await service.encryptPdfFile(
        sourceFilePath: samplePdf.path,
        targetFilePath: targetPath,
        config: config,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage,
          contains('at least a user or owner password is required'));
    });

    test('rejects non-existent source PDF file', () async {
      final missingPath = '${tempDir.path}/ghost.pdf';
      final targetPath = '${tempDir.path}/out.pdf';
      const config = PdfEncryptionConfig(userPassword: 'pass');

      final result = await service.encryptPdfFile(
        sourceFilePath: missingPath,
        targetFilePath: targetPath,
        config: config,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Source PDF file not found'));
    });
  });
}

PdfDocumentAst _createSamplePdf({required int pageCount}) {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};
  final pageRefs = <PdfRef>[];

  for (var i = 1; i <= pageCount; i++) {
    final pageId = 2 + i;
    objects[pageId] = PdfDict({
      'Type': const PdfName('Page'),
      'Parent': const PdfRef(2),
      'MediaBox': PdfArray(const [
        PdfNumber(0),
        PdfNumber(0),
        PdfNumber(612),
        PdfNumber(792),
      ]),
      'Contents': PdfStream(
        dict: PdfDict(const {'Length': PdfNumber(40)}),
        data: Uint8List.fromList(
            'BT /F1 12 Tf (Sample Page Text) Tj ET'.codeUnits),
      ),
    });
    gens[pageId] = 0;
    pageRefs.add(PdfRef(pageId));
  }

  final catalog = PdfDict(const {
    'Type': PdfName('Catalog'),
    'Pages': PdfRef(2),
  });
  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(pageRefs),
    'Count': PdfNumber(pageCount),
  });

  objects[1] = catalog;
  gens[1] = 0;
  objects[2] = pages;
  gens[2] = 0;

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}
