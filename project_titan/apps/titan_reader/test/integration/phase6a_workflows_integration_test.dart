import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_manipulation_engine.dart';
import 'package:titan_reader/src/manipulation/services/pdf_document_manipulation_service.dart';
import '../manipulation/phase6a_manipulation_engine_test.dart';

void main() {
  late Directory tempDir;
  late PdfDocumentManipulationService service;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('titan_phase6a_integration_');
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

  group('Phase 6A: End-to-End Workflows Integration Tests', () {
    test(
        'Workflow A: Open PDF -> Delete pages -> Save As -> Reopen output & verify',
        () async {
      final inputPdf =
          await createTestPdf('${tempDir.path}/workflowA_in.pdf', 6);
      final outPath = '${tempDir.path}/workflowA_out.pdf';

      final result = await service.deletePages(
        sourcePath: inputPdf.path,
        pagesToDelete: [2, 5],
        customOutputPath: outPath,
      );

      expect(result.pageCount, 4);
      expect(File(outPath).existsSync(), isTrue);

      final verifiedPages = await service.inspectPageCount(outPath);
      expect(verifiedPages, 4);
    });

    test('Workflow B: Open PDF -> Reorder pages -> Save -> Reopen & verify',
        () async {
      final inputPdf =
          await createTestPdf('${tempDir.path}/workflowB_in.pdf', 4);
      final outPath = '${tempDir.path}/workflowB_out.pdf';

      final result = await service.reorderPages(
        sourcePath: inputPdf.path,
        newOrder: [4, 3, 2, 1],
        customOutputPath: outPath,
      );

      expect(result.pageCount, 4);
      final verifiedPages = await service.inspectPageCount(outPath);
      expect(verifiedPages, 4);
    });

    test(
        'Workflow C: Open PDF -> Rotate selected pages -> Save -> Reopen & verify',
        () async {
      final inputPdf =
          await createTestPdf('${tempDir.path}/workflowC_in.pdf', 3);
      final outPath = '${tempDir.path}/workflowC_out.pdf';

      final result = await service.rotatePages(
        sourcePath: inputPdf.path,
        pageRotations: {1: 90, 3: 180},
        customOutputPath: outPath,
      );

      expect(result.pageCount, 3);
      final verifiedPages = await service.inspectPageCount(outPath);
      expect(verifiedPages, 3);
    });

    test('Workflow D: Select pages -> Extract -> Open extracted PDF & verify',
        () async {
      final inputPdf =
          await createTestPdf('${tempDir.path}/workflowD_in.pdf', 8);
      final outPath = '${tempDir.path}/workflowD_out.pdf';

      final result = await service.extractPages(
        sourcePath: inputPdf.path,
        pages: [2, 4, 6, 8],
        customOutputPath: outPath,
      );

      expect(result.pageCount, 4);
      final verifiedPages = await service.inspectPageCount(outPath);
      expect(verifiedPages, 4);
    });

    test('Workflow E: PDF A + PDF B -> Merge -> Open merged PDF & verify',
        () async {
      final pdfA = await createTestPdf('${tempDir.path}/docA.pdf', 4);
      final pdfB = await createTestPdf('${tempDir.path}/docB.pdf', 3);
      final outPath = '${tempDir.path}/merged_AB.pdf';

      final result = await service.mergePdfs(
        inputPaths: [pdfA.path, pdfB.path],
        customOutputPath: outPath,
      );

      expect(result.pageCount, 7);
      final verifiedPages = await service.inspectPageCount(outPath);
      expect(verifiedPages, 7);
    });
  });
}
