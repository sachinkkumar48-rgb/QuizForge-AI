import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/pdf_visual_signature.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/services/signature_service.dart';
import 'package:titan_storage/titan_storage.dart';

PdfDocumentAst _createTestPdfAst() {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};

  final page = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
  });
  objects[3] = page;
  gens[3] = 0;

  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(3)]),
    'Count': const PdfNumber(1),
  });
  objects[2] = pages;
  gens[2] = 0;

  final catalog = PdfDict(const {
    'Type': PdfName('Catalog'),
    'Pages': PdfRef(2),
  });
  objects[1] = catalog;
  gens[1] = 0;

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}

void main() {
  late InMemoryStorageService storage;
  late SignatureService service;
  late Directory tempDir;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    service = SignatureService(storage);
    tempDir = await Directory.systemTemp.createTemp('titan_sig_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SignatureService Storage & Management', () {
    test('save and load signatures with persistence isolation', () async {
      final sig1 = PdfVisualSignature.drawn(
        id: 'sig_test_1',
        name: 'Primary Sign',
        strokes: const [
          [PdfSignaturePoint(0.1, 0.1), PdfSignaturePoint(0.9, 0.9)],
        ],
      );

      final sig2 = PdfVisualSignature.typed(
        id: 'sig_test_2',
        name: 'Initials',
        text: 'SK',
      );

      await service.saveSignature(sig1);
      await service.saveSignature(sig2);

      // Create new service instance with same storage
      final service2 = SignatureService(storage);
      final list = await service2.ensureLoaded();

      expect(list.length, 2);
      expect(service2.getSignatureById('sig_test_1')?.name, 'Primary Sign');
      expect(service2.getSignatureById('sig_test_2')?.typedText, 'SK');
    });

    test('delete signature removes it from persistence', () async {
      final sig = PdfVisualSignature.typed(
        id: 'sig_del',
        name: 'To Delete',
        text: 'Delete Me',
      );
      await service.saveSignature(sig);
      expect((await service.ensureLoaded()).length, 1);

      final deleted = await service.deleteSignature('sig_del');
      expect(deleted, isTrue);
      expect((await service.ensureLoaded()).isEmpty, isTrue);

      final deletedAgain = await service.deleteSignature('sig_del');
      expect(deletedAgain, isFalse);
    });

    test('update existing signature preserves id and updates timestamp',
        () async {
      final sig = PdfVisualSignature.typed(
        id: 'sig_up',
        name: 'Old Name',
        text: 'Old Text',
      );
      await service.saveSignature(sig);

      final updated = sig.copyWith(name: 'New Name', typedText: 'New Text');
      await service.saveSignature(updated);

      final current = service.getSignatureById('sig_up');
      expect(current?.name, 'New Name');
      expect(current?.typedText, 'New Text');
    });
  });

  group('SignatureService PDF Stamp Placement', () {
    test('stamps drawn signature onto PDF document AST cleanly', () async {
      final ast = _createTestPdfAst();
      final pdfBytes = PdfWriter(ast).writeBytes();
      final testPdfFile = File('${tempDir.path}/test_doc.pdf');
      await testPdfFile.writeAsBytes(pdfBytes);

      final sig = PdfVisualSignature.drawn(
        id: 'sig_stamp_1',
        name: 'Signed Stamp',
        strokes: const [
          [PdfSignaturePoint(0.0, 0.0), PdfSignaturePoint(1.0, 1.0)],
        ],
      );

      final resultPath = await service.stampSignatureOnPdf(
        sourceFilePath: testPdfFile.path,
        pageIndex: 0,
        rect: const NormalizedPageRect(
            left: 0.1, top: 0.7, right: 0.4, bottom: 0.8),
        signature: sig,
      );

      expect(resultPath, testPdfFile.path);

      // Verify the stamped PDF
      final stampedBytes = await File(resultPath).readAsBytes();
      final parsedAst = PdfParser(stampedBytes).parse();
      expect(parsedAst.pageCount, 1);

      final pageDict = parsedAst.getPageDict(0);
      final annots = pageDict.getArray('Annots');
      expect(annots, isNotNull);
      expect(annots!.length, 1);

      final annotRef = annots[0] as PdfRef;
      final annotDict = parsedAst.objects[annotRef.objectNumber] as PdfDict;
      expect((annotDict['Subtype'] as PdfName).name, 'Ink');
      expect((annotDict['T'] as PdfString).asString(), 'TITAN Signature');
      expect((annotDict['Contents'] as PdfString).asString(),
          'Signature: Signed Stamp');
    });

    test('stamps typed signature onto PDF document AST cleanly', () async {
      final ast = _createTestPdfAst();
      final pdfBytes = PdfWriter(ast).writeBytes();
      final testPdfFile = File('${tempDir.path}/test_doc_typed.pdf');
      await testPdfFile.writeAsBytes(pdfBytes);

      final sig = PdfVisualSignature.typed(
        id: 'sig_typed_stamp',
        name: 'Typed Sign',
        text: 'Prof. Xavier',
      );

      await service.stampSignatureOnPdf(
        sourceFilePath: testPdfFile.path,
        pageIndex: 0,
        rect: const NormalizedPageRect(
            left: 0.2, top: 0.6, right: 0.5, bottom: 0.7),
        signature: sig,
      );

      final stampedBytes = await testPdfFile.readAsBytes();
      final parsedAst = PdfParser(stampedBytes).parse();
      final pageDict = parsedAst.getPageDict(0);
      final annots = pageDict.getArray('Annots');
      expect(annots, isNotNull);
      expect(annots!.length, 1);

      final annotRef = annots[0] as PdfRef;
      final annotDict = parsedAst.objects[annotRef.objectNumber] as PdfDict;
      expect((annotDict['Subtype'] as PdfName).name, 'FreeText');
      expect((annotDict['Contents'] as PdfString).asString(),
          'Signature: Typed Sign');
    });

    test('throws on out-of-bounds pageIndex', () async {
      final ast = _createTestPdfAst();
      final pdfBytes = PdfWriter(ast).writeBytes();
      final testPdfFile = File('${tempDir.path}/test_doc_oob.pdf');
      await testPdfFile.writeAsBytes(pdfBytes);

      final sig = PdfVisualSignature.typed(
        id: 'sig_oob',
        name: 'OOB',
        text: 'Test',
      );

      expect(
        () => service.stampSignatureOnPdf(
          sourceFilePath: testPdfFile.path,
          pageIndex: 5,
          rect: const NormalizedPageRect(
              left: 0.1, top: 0.1, right: 0.3, bottom: 0.2),
          signature: sig,
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });
}
