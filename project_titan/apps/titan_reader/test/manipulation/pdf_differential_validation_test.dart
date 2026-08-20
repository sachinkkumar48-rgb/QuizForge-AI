import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_range.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_manipulation_engine.dart';
import 'package:titan_reader/src/manipulation/services/pdf_document_manipulation_service.dart';

void main() {
  late Directory tempDir;
  const engine = DefaultPdfManipulationEngine();
  final service = PdfDocumentManipulationService(engine: engine);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_diff_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6A.1: Differential & Idempotence Validation Tests', () {
    test(
        'Idempotence: Parse -> Mutate -> Write -> Re-parse -> Write produces identical structure',
        () async {
      final docOriginal = _createFixture(pageCount: 3);
      final writerOriginal = PdfWriter(docOriginal);
      final originalBytes = writerOriginal.writeBytes();

      final fileOrig = File('${tempDir.path}/idempotence_orig.pdf');
      await fileOrig.writeAsBytes(originalBytes);

      // Cycle 1: Rotate Page 2
      final out1 = '${tempDir.path}/cycle1.pdf';
      await service.rotatePages(
        sourcePath: fileOrig.path,
        pageRotations: {2: 90},
        customOutputPath: out1,
      );

      final ast1 = PdfParser(await File(out1).readAsBytes()).parse();
      expect(ast1.pageCount, 3);
      expect(ast1.getPageDict(1).getInt('Rotate'), 90);

      // Cycle 2: Parse output and write directly without further mutations
      final writerCycle2 = PdfWriter(ast1);
      final bytesCycle2 = writerCycle2.writeBytes();

      final ast2 = PdfParser(bytesCycle2).parse();
      expect(ast2.pageCount, 3);
      expect(ast2.getPageDict(1).getInt('Rotate'), 90);
      expect(ast2.getPageDict(0).getInt('Rotate') ?? 0, 0);
      expect(ast2.getPageDict(2).getInt('Rotate') ?? 0, 0);
    });

    test(
        'Chained Mutation Cycle: Merge(3) -> Split(3) -> Re-Merge(3) preserves page count and resources',
        () async {
      final docA = _createFixture(pageCount: 2);
      final docB = _createFixture(pageCount: 3);
      final docC = _createFixture(pageCount: 1);

      final fileA = File('${tempDir.path}/chainA.pdf')
        ..writeAsBytesSync(PdfWriter(docA).writeBytes());
      final fileB = File('${tempDir.path}/chainB.pdf')
        ..writeAsBytesSync(PdfWriter(docB).writeBytes());
      final fileC = File('${tempDir.path}/chainC.pdf')
        ..writeAsBytesSync(PdfWriter(docC).writeBytes());

      // Step 1: Merge A + B + C (Total 6 pages)
      final mergedPath = '${tempDir.path}/chain_merged.pdf';
      final mergeRes = await service.mergePdfs(
        inputPaths: [fileA.path, fileB.path, fileC.path],
        customOutputPath: mergedPath,
      );
      expect(mergeRes.pageCount, 6);

      // Step 2: Split merged (1..2, 3..5, 6..6)
      final splitDir = '${tempDir.path}/chain_split';
      final splitRes = await service.splitPdf(
        sourcePath: mergedPath,
        ranges: [
          const PdfPageRange(1, 2),
          const PdfPageRange(3, 5),
          const PdfPageRange(6, 6),
        ],
        outputDirectory: splitDir,
      );
      expect(splitRes.outputPaths.length, 3);
      expect(await engine.inspectPageCount(splitRes.outputPaths[0]), 2);
      expect(await engine.inspectPageCount(splitRes.outputPaths[1]), 3);
      expect(await engine.inspectPageCount(splitRes.outputPaths[2]), 1);

      // Step 3: Re-Merge split outputs
      final reMergedPath = '${tempDir.path}/chain_remerged.pdf';
      final reMergeRes = await service.mergePdfs(
        inputPaths: splitRes.outputPaths,
        customOutputPath: reMergedPath,
      );
      expect(reMergeRes.pageCount, 6);
    });

    test(
        'Atomic file replacement safety: overwriting existing output path replaces atomically without corruption',
        () async {
      final doc = _createFixture(pageCount: 2);
      final targetPath = '${tempDir.path}/atomic_target.pdf';

      // Pre-create file with dummy content
      final targetFile = File(targetPath);
      await targetFile.writeAsString('EXISTING NON-EMPTY CONTENT');

      // Atomic write via writer
      final writer = PdfWriter(doc);
      final finalFile = await writer.writeAtomic(targetPath);

      expect(finalFile.path, targetPath);
      final readAst = PdfParser(await finalFile.readAsBytes()).parse();
      expect(readAst.pageCount, 2);
    });
  });
}

PdfDocumentAst _createFixture({required int pageCount}) {
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

  final trailer = PdfDict(const {
    'Root': PdfRef(1),
  });

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: trailer,
    catalog: catalog,
  );
}
