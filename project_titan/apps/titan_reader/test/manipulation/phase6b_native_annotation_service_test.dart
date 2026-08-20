import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_native_annotation.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/services/pdf_native_annotation_service.dart';

void main() {
  late Directory tempDir;
  late PdfNativeAnnotationService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_service_test_');
    service = PdfNativeAnnotationService();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6B: PdfNativeAnnotationService Undo/Redo & Safe Export Tests',
      () {
    test('addAnnotation with undo and redo operations', () async {
      final doc = _createTestPdf(pageCount: 1);
      final pdfFile = File('${tempDir.path}/undo_test.pdf');
      await pdfFile.writeAsBytes(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      const box = PdfBoundingBox(left: 100, bottom: 600, right: 300, top: 620);
      final annot = PdfNativeHighlightAnnotation(
        id: 'hl-undo-1',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        quadPoints: [PdfQuadPoint.fromBox(box)],
        contents: 'Undoable highlight',
      );

      // Add
      await service.addAnnotation(sourcePath: pdfFile.path, annotation: annot);
      expect((await service.loadAnnotations(pdfFile.path)).length, 1);
      expect(service.undoStack.canUndo, isTrue);

      // Undo
      service.undoStack.undo();
      expect((await service.loadAnnotations(pdfFile.path)).length, 0);
      expect(service.undoStack.canRedo, isTrue);

      // Redo
      service.undoStack.redo();
      expect((await service.loadAnnotations(pdfFile.path)).length, 1);
    });

    test('updateAnnotation and deleteAnnotation with undo/redo', () async {
      final doc = _createTestPdf(pageCount: 1);
      final pdfFile = File('${tempDir.path}/update_undo.pdf');
      await pdfFile.writeAsBytes(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      const box = PdfBoundingBox(left: 100, bottom: 600, right: 300, top: 620);
      final annot = PdfNativeHighlightAnnotation(
        id: 'hl-up-1',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        quadPoints: [PdfQuadPoint.fromBox(box)],
        contents: 'Initial text',
      );

      await service.addAnnotation(sourcePath: pdfFile.path, annotation: annot);

      final updated = annot.copyWith(contents: 'Updated text');
      await service.updateAnnotation(
        sourcePath: pdfFile.path,
        annotation: updated,
        previousAnnotation: annot,
      );

      expect((await service.loadAnnotations(pdfFile.path)).first.contents,
          'Updated text');

      // Undo update
      service.undoStack.undo();
      expect((await service.loadAnnotations(pdfFile.path)).first.contents,
          'Initial text');

      // Redo update
      service.undoStack.redo();
      expect((await service.loadAnnotations(pdfFile.path)).first.contents,
          'Updated text');

      // Delete
      await service.deleteAnnotation(
        sourcePath: pdfFile.path,
        annotation: updated,
      );
      expect((await service.loadAnnotations(pdfFile.path)).length, 0);

      // Undo delete
      service.undoStack.undo();
      expect((await service.loadAnnotations(pdfFile.path)).length, 1);
    });

    test('Non-destructive filename generation for export and flattening', () {
      final path1 = service.generateAnnotatedOutputPath('C:/docs/report.pdf');
      expect(path1, 'C:/docs/report_annotated.pdf');

      final path2 = service.generateFlattenedOutputPath('C:/docs/report.pdf');
      expect(path2, 'C:/docs/report_flattened.pdf');
    });
  });
}

PdfDocumentAst _createTestPdf({required int pageCount}) {
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

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}
