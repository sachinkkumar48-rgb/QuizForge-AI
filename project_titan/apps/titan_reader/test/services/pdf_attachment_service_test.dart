import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/services/pdf_attachment_service.dart';

void main() {
  late Directory tempDir;
  late File samplePdfFile;
  late PdfAttachmentService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_attachment_test_');
    samplePdfFile = File('${tempDir.path}/sample_with_attachments.pdf');

    final ast = _createSamplePdfWithAttachment();
    final writer = PdfWriter(ast);
    await samplePdfFile.writeAsBytes(writer.writeBytes());

    service = const PdfAttachmentService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfAttachmentService Tests', () {
    test('lists embedded attachments from PDF file', () async {
      final attachments =
          await service.listAttachments(filePath: samplePdfFile.path);
      expect(attachments.length, 1);
      expect(attachments.first.filename, 'embedded_notes.txt');
      expect(attachments.first.declaredSize, 25);
    });

    test(
        'extracts single attachment to target directory and preserves original PDF',
        () async {
      final originalBytes = await samplePdfFile.readAsBytes();
      final extractDir = '${tempDir.path}/extracted';

      final attachments =
          await service.listAttachments(filePath: samplePdfFile.path);
      expect(attachments.isNotEmpty, isTrue);

      final result = await service.extractAttachment(
        sourceFilePath: samplePdfFile.path,
        attachment: attachments.first,
        targetDirectoryPath: extractDir,
      );

      expect(result.isSuccess, isTrue);
      expect(result.outputPath?.replaceAll(r'\', '/'),
          '${extractDir.replaceAll(r'\', '/')}/embedded_notes.txt');
      expect(result.extractedBytesCount, 25);

      // Verify extracted file content
      final extractedFile = File(result.outputPath!);
      expect(await extractedFile.exists(), isTrue);
      final extractedText = await extractedFile.readAsString();
      expect(extractedText, 'Important attachment data');

      // Verify original file is 100% untouched
      final afterOriginalBytes = await samplePdfFile.readAsBytes();
      expect(afterOriginalBytes, equals(originalBytes));
    });

    test('extracts all attachments in batch', () async {
      final extractDir = '${tempDir.path}/batch_extracted';
      final results = await service.extractAllAttachments(
        sourceFilePath: samplePdfFile.path,
        targetDirectoryPath: extractDir,
      );

      expect(results.length, 1);
      expect(results.first.isSuccess, isTrue);
    });

    test('handles empty or missing source files gracefully', () async {
      final emptyResult = await service.extractAttachment(
        sourceFilePath: '',
        attachment:
            (await service.listAttachments(filePath: samplePdfFile.path)).first,
        targetDirectoryPath: tempDir.path,
      );
      expect(emptyResult.isFailure, isTrue);

      final missingResult = await service.extractAttachment(
        sourceFilePath: '${tempDir.path}/non_existent.pdf',
        attachment:
            (await service.listAttachments(filePath: samplePdfFile.path)).first,
        targetDirectoryPath: tempDir.path,
      );
      expect(missingResult.isFailure, isTrue);
    });
  });
}

PdfDocumentAst _createSamplePdfWithAttachment() {
  final payload = utf8.encode('Important attachment data');

  final streamObj = PdfStream(
    dict: PdfDict({
      'Type': const PdfName('EmbeddedFile'),
      'Subtype': const PdfName('text#2Fplain'),
      'Params': PdfDict({'Size': PdfNumber(payload.length)}),
    }),
    data: Uint8List.fromList(payload),
  );

  final spec = PdfDict({
    'Type': const PdfName('Filespec'),
    'UF': PdfString.fromString('embedded_notes.txt'),
    'F': PdfString.fromString('embedded_notes.txt'),
    'EF': PdfDict(const {'UF': PdfRef(10)}),
  });

  final tree = PdfDict({
    'Names': PdfArray([
      PdfString.fromString('embedded_notes.txt'),
      const PdfRef(9),
    ]),
  });

  final page = PdfDict({
    'Type': const PdfName('Page'),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
  });

  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(3)]),
    'Count': const PdfNumber(1),
  });

  final catalog = PdfDict({
    'Type': const PdfName('Catalog'),
    'Pages': const PdfRef(2),
    'Names': PdfDict(const {'EmbeddedFiles': PdfRef(8)}),
  });

  final objects = <int, PdfObject>{
    1: catalog,
    2: pages,
    3: page,
    8: tree,
    9: spec,
    10: streamObj,
  };

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: const {1: 0, 2: 0, 3: 0, 8: 0, 9: 0, 10: 0},
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}
