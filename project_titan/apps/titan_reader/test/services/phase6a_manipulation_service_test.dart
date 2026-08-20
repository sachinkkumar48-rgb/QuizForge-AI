import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_range.dart';
import 'package:titan_reader/src/domain/pdf_manipulation_errors.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_manipulation_engine.dart';
import 'package:titan_reader/src/manipulation/services/pdf_document_manipulation_service.dart';
import '../manipulation/phase6a_manipulation_engine_test.dart';

void main() {
  late Directory tempDir;
  late PdfDocumentManipulationService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_phase6a_svc_test_');
    service = PdfDocumentManipulationService(
      engine: const DefaultPdfManipulationEngine(),
    );
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6A: PdfDocumentManipulationService Tests', () {
    test('generateSafeOutputPath prevents clobbering existing files', () async {
      final basePdf = await createTestPdf('${tempDir.path}/test_doc.pdf', 2);
      final p1 = service.generateSafeOutputPath(basePdf.path, 'reordered');
      expect(p1.endsWith('test_doc_reordered.pdf'), isTrue);

      // Create existing file at p1
      await File(p1).writeAsString('dummy');

      final p2 = service.generateSafeOutputPath(basePdf.path, 'reordered');
      expect(p2.endsWith('test_doc_reordered_1.pdf'), isTrue);
    });

    test('Preflight rejects non-existent input files', () async {
      expect(
        () => service.extractPages(
            sourcePath: '${tempDir.path}/missing.pdf', pages: [1]),
        throwsA(isA<PdfInvalidDocumentException>()),
      );
    });

    test('Full safe workflows via service execute and verify outputs',
        () async {
      final docA = await createTestPdf('${tempDir.path}/serviceA.pdf', 3);
      final docB = await createTestPdf('${tempDir.path}/serviceB.pdf', 2);

      // Merge
      final mergeRes =
          await service.mergePdfs(inputPaths: [docA.path, docB.path]);
      expect(mergeRes.pageCount, 5);
      expect(File(mergeRes.primaryOutputPath).existsSync(), isTrue);

      // Split
      final splitRes = await service.splitPdf(
        sourcePath: mergeRes.primaryOutputPath,
        ranges: [const PdfPageRange(1, 2), const PdfPageRange(3, 5)],
      );
      expect(splitRes.outputPaths.length, 2);

      // Reorder
      final reorderRes = await service.reorderPages(
        sourcePath: docA.path,
        newOrder: [3, 2, 1],
      );
      expect(reorderRes.pageCount, 3);

      // Rotate
      final rotateRes = await service.rotatePages(
        sourcePath: docA.path,
        pageRotations: {1: 90},
      );
      expect(rotateRes.pageCount, 3);
    });
  });
}
