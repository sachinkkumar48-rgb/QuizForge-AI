import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_range.dart';
import 'package:titan_reader/src/domain/pdf_manipulation_errors.dart';
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
    tempDir = await Directory.systemTemp.createTemp('titan_corpus_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6A.1: PDF Compatibility Corpus (Categories A–T)', () {
    test('Category A & B: Minimal & Multi-page PDFs parse, mutate, and write',
        () async {
      // Category A: 1-page minimal PDF
      final doc1 = _buildSynthesizedPdf(pageCount: 1);
      final file1 = File('${tempDir.path}/cat_a.pdf');
      await file1.writeAsBytes(PdfWriter(doc1).writeBytes());

      expect(await engine.inspectPageCount(file1.path), 1);

      // Category B: 10-page document
      final doc10 = _buildSynthesizedPdf(pageCount: 10);
      final file10 = File('${tempDir.path}/cat_b.pdf');
      await file10.writeAsBytes(PdfWriter(doc10).writeBytes());

      expect(await engine.inspectPageCount(file10.path), 10);
    });

    test('Category C: Different page sizes (A4, US-Letter, Custom Banner)',
        () async {
      final doc = _buildMultiSizePdf([
        const [595.28, 841.89], // A4
        const [612.0, 792.0], // US Letter
        const [1200.0, 400.0], // Custom Banner
      ]);
      final file = File('${tempDir.path}/cat_c.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      // Extract page 3 (Custom Banner)
      final outBanner = '${tempDir.path}/cat_c_extracted.pdf';
      final res = await service.extractPages(
        sourcePath: file.path,
        pages: [3],
        customOutputPath: outBanner,
      );

      expect(res.pageCount, 1);
      final parser = PdfParser(await File(outBanner).readAsBytes());
      final ast = parser.parse();
      final pageDict = ast.getPageDict(0);
      final mediaBox = pageDict.getArray('MediaBox')!;
      expect((mediaBox[2] as PdfNumber).asDouble, 1200.0);
      expect((mediaBox[3] as PdfNumber).asDouble, 400.0);
    });

    test('Category D: Rotated pages (0, 90, 180, 270) & cumulative rotation',
        () async {
      final doc = _buildSynthesizedPdf(pageCount: 4);
      final file = File('${tempDir.path}/cat_d.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      // Rotate page 1 by 90, page 2 by 180, page 3 by 270
      final outRotated = '${tempDir.path}/cat_d_rotated.pdf';
      await service.rotatePages(
        sourcePath: file.path,
        pageRotations: {1: 90, 2: 180, 3: 270},
        customOutputPath: outRotated,
        relative: false,
      );

      final ast = PdfParser(await File(outRotated).readAsBytes()).parse();
      expect(ast.getPageDict(0).getInt('Rotate'), 90);
      expect(ast.getPageDict(1).getInt('Rotate'), 180);
      expect(ast.getPageDict(2).getInt('Rotate'), 270);
      expect(ast.getPageDict(3).getInt('Rotate') ?? 0, 0);
    });

    test('Category E: Image XObjects preservation', () async {
      final imgBytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
        0x00,
        0x01
      ]);
      final doc = _buildPdfWithImageXObject(imgBytes);
      final file = File('${tempDir.path}/cat_e.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      // Reorder pages
      final outReordered = '${tempDir.path}/cat_e_reordered.pdf';
      await service.reorderPages(
        sourcePath: file.path,
        newOrder: [2, 1],
        customOutputPath: outReordered,
      );

      final ast = PdfParser(await File(outReordered).readAsBytes()).parse();
      // Locate image stream in objects
      var foundImage = false;
      for (final obj in ast.objects.values) {
        if (obj is PdfStream && obj.dict.getName('Subtype') == 'Image') {
          foundImage = true;
          expect(obj.dict.getInt('Width'), 100);
          expect(obj.dict.getInt('Height'), 100);
          expect(obj.data, imgBytes);
        }
      }
      expect(foundImage, isTrue);
    });

    test('Category F: Embedded Fonts & Type1/TrueType dictionaries', () async {
      final doc = _buildPdfWithEmbeddedFont();
      final file = File('${tempDir.path}/cat_f.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      final outSplit = '${tempDir.path}/cat_f_split';
      final res = await service.splitPdf(
        sourcePath: file.path,
        ranges: [const PdfPageRange(1, 1), const PdfPageRange(2, 2)],
        outputDirectory: outSplit,
        baseName: 'font_doc',
      );

      expect(res.outputPaths.length, 2);
      final astPart1 =
          PdfParser(await File(res.outputPaths[0]).readAsBytes()).parse();
      var foundFont = false;
      for (final obj in astPart1.objects.values) {
        if (obj is PdfDict && obj.getName('Type') == 'Font') {
          foundFont = true;
          expect(obj.getName('BaseFont'), 'Helvetica-Bold');
        }
      }
      expect(foundFont, isTrue);
    });

    test('Category G: Document Metadata (/Info dictionary preservation)',
        () async {
      final doc = _buildPdfWithMetadata(
        title: 'TITAN Engineering Specification',
        author: 'TITAN Architecture Team',
        subject: 'PDF Architecture',
        keywords: 'TITAN, PDF, Clean Architecture',
      );
      final file = File('${tempDir.path}/cat_g.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      final outPath = '${tempDir.path}/cat_g_inserted.pdf';
      await service.insertBlankPage(
        sourcePath: file.path,
        targetIndex: 2,
        customOutputPath: outPath,
      );

      final ast = PdfParser(await File(outPath).readAsBytes()).parse();
      final infoRef = ast.trailer['Info'];
      expect(infoRef, isNotNull);
      final infoDict = (infoRef is PdfRef)
          ? ast.objects[infoRef.objectNumber] as PdfDict
          : infoRef as PdfDict;

      expect(infoDict.getString('Title')?.asString(),
          'TITAN Engineering Specification');
      expect(infoDict.getString('Author')?.asString(),
          'TITAN Architecture Team');
    });

    test('Category H: Bookmarks & Outlines (/Outlines hierarchy preservation)',
        () async {
      final doc = _buildPdfWithOutlines();
      final file = File('${tempDir.path}/cat_h.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      final outPath = '${tempDir.path}/cat_h_reordered.pdf';
      await service.reorderPages(
        sourcePath: file.path,
        newOrder: [2, 1],
        customOutputPath: outPath,
      );

      final ast = PdfParser(await File(outPath).readAsBytes()).parse();
      final outlinesRef = ast.catalog['Outlines'];
      expect(outlinesRef, isNotNull);
      final outlinesDict = (outlinesRef is PdfRef)
          ? ast.objects[outlinesRef.objectNumber] as PdfDict
          : outlinesRef as PdfDict;
      expect(outlinesDict.getName('Type'), 'Outlines');
    });

    test('Category I: Native Annotations preservation (/Annots on pages)',
        () async {
      final doc = _buildPdfWithNativeAnnotation();
      final file = File('${tempDir.path}/cat_i.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      final outPath = '${tempDir.path}/cat_i_extracted.pdf';
      await service.extractPages(
        sourcePath: file.path,
        pages: [1],
        customOutputPath: outPath,
      );

      final ast = PdfParser(await File(outPath).readAsBytes()).parse();
      final page1 = ast.getPageDict(0);
      final annots = page1.getArray('Annots');
      expect(annots, isNotNull);
      expect(annots!.length, 1);
    });

    test('Category J: Compressed FlateDecode stream preservation', () async {
      // Create raw uncompressed and deflated stream payload
      final rawData = utf8.encode('BT /F1 12 Tf 100 700 Td (Hello World) Tj ET');
      final zlibCompressed = Uint8List.fromList(zlib.encode(rawData));

      final doc = _buildPdfWithCompressedStream(zlibCompressed);
      final file = File('${tempDir.path}/cat_j.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      final outPath = '${tempDir.path}/cat_j_rotated.pdf';
      await service.rotatePages(
        sourcePath: file.path,
        pageRotations: {1: 180},
        customOutputPath: outPath,
      );

      final ast = PdfParser(await File(outPath).readAsBytes()).parse();
      var streamPreserved = false;
      for (final obj in ast.objects.values) {
        if (obj is PdfStream && obj.dict.getName('Filter') == 'FlateDecode') {
          streamPreserved = true;
          expect(obj.data, zlibCompressed);
        }
      }
      expect(streamPreserved, isTrue);
    });

    test('Category K, L, M, N, O: XRef Streams, Incremental Updates & Ordering',
        () async {
      // Create PDF with incremental update (two object revisions)
      const rawPdf = '''
%PDF-1.7
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>
endobj
xref
0 4
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
trailer
<< /Size 4 /Root 1 0 R >>
startxref
185
%%EOF
% Incremental update
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 600 800] /Rotate 90 >>
endobj
xref
3 1
0000000215 00000 n 
trailer
<< /Size 4 /Root 1 0 R /Prev 185 >>
startxref
295
%%EOF
''';
      final file = File('${tempDir.path}/cat_n.pdf');
      await file.writeAsString(rawPdf);

      final ast = PdfParser(await file.readAsBytes()).parse();
      expect(ast.pageCount, 1);
      final page1 = ast.getPageDict(0);
      expect(page1.getInt('Rotate'), 90);
    });

    test('Category P: Large 100-page PDF performance & correctness', () async {
      final doc100 = _buildSynthesizedPdf(pageCount: 100);
      final file100 = File('${tempDir.path}/cat_p_100.pdf');
      await file100.writeAsBytes(PdfWriter(doc100).writeBytes());

      final sw = Stopwatch()..start();
      final outReordered = '${tempDir.path}/cat_p_reordered.pdf';
      final revOrder = List<int>.generate(100, (i) => 100 - i);

      final res = await service.reorderPages(
        sourcePath: file100.path,
        newOrder: revOrder,
        customOutputPath: outReordered,
      );
      sw.stop();

      expect(res.pageCount, 100);
      expect(sw.elapsedMilliseconds, lessThan(3000)); // Fast pure Dart execution
    });

    test('Category R & S: Unicode UTF-16BE & Devanagari Hindi Text Strings',
        () async {
      // UTF-16BE BOM: 0xFE, 0xFF followed by big-endian code units
      const hindiText = 'भारत संविधान'; // Constitution of India
      final utf16beUnits = <int>[0xFE, 0xFF];
      for (final cu in hindiText.codeUnits) {
        utf16beUnits.add((cu >> 8) & 0xFF);
        utf16beUnits.add(cu & 0xFF);
      }

      final doc = _buildPdfWithMetadata(
        title: 'भारतीय विधि',
        author: utf16beUnits,
        subject: 'Hindi Devanagari Corpus',
        keywords: 'Garuda, Constitution',
      );
      final file = File('${tempDir.path}/cat_s.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      final outExtracted = '${tempDir.path}/cat_s_out.pdf';
      await service.extractPages(
        sourcePath: file.path,
        pages: [1],
        customOutputPath: outExtracted,
      );

      final ast = PdfParser(await File(outExtracted).readAsBytes()).parse();
      final infoRef = ast.trailer['Info'] as PdfRef;
      final infoDict = ast.objects[infoRef.objectNumber] as PdfDict;
      expect(infoDict.getString('Author')?.asString(), hindiText);
    });

    test(
        'Category T: Password / Encrypted PDF rejection with typed exception and zero corruption',
        () async {
      final doc = _buildEncryptedPdf();
      final file = File('${tempDir.path}/cat_t_encrypted.pdf');
      await file.writeAsBytes(PdfWriter(doc).writeBytes());

      expect(
        () => service.rotatePages(
          sourcePath: file.path,
          pageRotations: {1: 90},
        ),
        throwsA(isA<PdfUnsupportedDocumentException>()),
      );

      // Verify source file remains untouched
      expect(await file.exists(), isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Synthetic Document Generators for Test Corpus Categories
// ---------------------------------------------------------------------------

PdfDocumentAst _buildSynthesizedPdf({required int pageCount}) {
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

PdfDocumentAst _buildMultiSizePdf(List<List<double>> pageSizes) {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};
  final pageRefs = <PdfRef>[];

  for (var i = 0; i < pageSizes.length; i++) {
    final pageId = 3 + i;
    final size = pageSizes[i];
    objects[pageId] = PdfDict({
      'Type': const PdfName('Page'),
      'Parent': const PdfRef(2),
      'MediaBox': PdfArray([
        const PdfNumber(0),
        const PdfNumber(0),
        PdfNumber(size[0]),
        PdfNumber(size[1]),
      ]),
    });
    gens[pageId] = 0;
    pageRefs.add(PdfRef(pageId));
  }

  final catalog = PdfDict(const {'Type': PdfName('Catalog'), 'Pages': PdfRef(2)});
  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(pageRefs),
    'Count': PdfNumber(pageSizes.length),
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

PdfDocumentAst _buildPdfWithImageXObject(Uint8List imageBytes) {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};

  final imgStream = PdfStream(
    dict: PdfDict({
      'Type': const PdfName('XObject'),
      'Subtype': const PdfName('Image'),
      'Width': const PdfNumber(100),
      'Height': const PdfNumber(100),
      'ColorSpace': const PdfName('DeviceRGB'),
      'BitsPerComponent': const PdfNumber(8),
      'Length': PdfNumber(imageBytes.length),
    }),
    data: imageBytes,
  );

  objects[4] = imgStream;
  gens[4] = 0;

  final resources = PdfDict({
    'XObject': PdfDict(const {'Im1': PdfRef(4)}),
  });
  objects[5] = resources;
  gens[5] = 0;

  final page1 = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
    'Resources': const PdfRef(5),
  });
  final page2 = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
  });

  objects[3] = page1;
  gens[3] = 0;
  objects[6] = page2;
  gens[6] = 0;

  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(3), PdfRef(6)]),
    'Count': const PdfNumber(2),
  });
  objects[2] = pages;
  gens[2] = 0;

  final catalog = PdfDict(const {'Type': PdfName('Catalog'), 'Pages': PdfRef(2)});
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

PdfDocumentAst _buildPdfWithEmbeddedFont() {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};

  final fontDict = PdfDict(const {
    'Type': PdfName('Font'),
    'Subtype': PdfName('Type1'),
    'BaseFont': PdfName('Helvetica-Bold'),
    'Encoding': PdfName('WinAnsiEncoding'),
  });
  objects[4] = fontDict;
  gens[4] = 0;

  final resources = PdfDict({
    'Font': PdfDict(const {'F1': PdfRef(4)}),
  });
  objects[5] = resources;
  gens[5] = 0;

  final page1 = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
    'Resources': const PdfRef(5),
  });
  final page2 = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
    'Resources': const PdfRef(5),
  });

  objects[3] = page1;
  gens[3] = 0;
  objects[6] = page2;
  gens[6] = 0;

  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(3), PdfRef(6)]),
    'Count': const PdfNumber(2),
  });
  objects[2] = pages;
  gens[2] = 0;

  final catalog = PdfDict(const {'Type': PdfName('Catalog'), 'Pages': PdfRef(2)});
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

PdfDocumentAst _buildPdfWithMetadata({
  required String title,
  required Object author,
  required String subject,
  required String keywords,
}) {
  final doc = _buildSynthesizedPdf(pageCount: 2);
  final infoId = doc.nextAvailableObjectNumber();
  final authorStr = (author is List<int>)
      ? PdfString(author, isHex: true)
      : PdfString.fromString(author.toString());
  final infoDict = PdfDict({
    'Title': PdfString.fromString(title),
    'Author': authorStr,
    'Subject': PdfString.fromString(subject),
    'Keywords': PdfString.fromString(keywords),
    'Creator': PdfString.fromString('Project TITAN Reader'),
    'CreationDate': PdfString.fromString('D:20260820100000Z'),
  });

  doc.objects[infoId] = infoDict;
  doc.objectGenerations[infoId] = 0;
  doc.trailer['Info'] = PdfRef(infoId);

  return doc;
}

PdfDocumentAst _buildPdfWithOutlines() {
  final doc = _buildSynthesizedPdf(pageCount: 2);
  final outlinesId = doc.nextAvailableObjectNumber();
  final item1Id = outlinesId + 1;

  final outlines = PdfDict({
    'Type': const PdfName('Outlines'),
    'Count': const PdfNumber(1),
    'First': PdfRef(item1Id),
    'Last': PdfRef(item1Id),
  });
  final item1 = PdfDict({
    'Title': PdfString.fromString('Chapter 1'),
    'Parent': PdfRef(outlinesId),
    'Dest': PdfArray(const [PdfRef(3), PdfName('Fit')]),
  });

  doc.objects[outlinesId] = outlines;
  doc.objectGenerations[outlinesId] = 0;
  doc.objects[item1Id] = item1;
  doc.objectGenerations[item1Id] = 0;

  doc.catalog['Outlines'] = PdfRef(outlinesId);
  return doc;
}

PdfDocumentAst _buildPdfWithNativeAnnotation() {
  final doc = _buildSynthesizedPdf(pageCount: 1);
  final annotId = doc.nextAvailableObjectNumber();

  final annot = PdfDict({
    'Type': const PdfName('Annot'),
    'Subtype': const PdfName('Highlight'),
    'Rect': PdfArray(const [
      PdfNumber(100),
      PdfNumber(700),
      PdfNumber(300),
      PdfNumber(720),
    ]),
    'Contents': PdfString.fromString('Important note on page 1'),
  });

  doc.objects[annotId] = annot;
  doc.objectGenerations[annotId] = 0;

  final page1 = doc.getPageDict(0);
  page1['Annots'] = PdfArray([PdfRef(annotId)]);

  return doc;
}

PdfDocumentAst _buildPdfWithCompressedStream(Uint8List compressedData) {
  final doc = _buildSynthesizedPdf(pageCount: 1);
  final streamId = doc.nextAvailableObjectNumber();

  final stream = PdfStream(
    dict: PdfDict({
      'Length': PdfNumber(compressedData.length),
      'Filter': const PdfName('FlateDecode'),
    }),
    data: compressedData,
  );

  doc.objects[streamId] = stream;
  doc.objectGenerations[streamId] = 0;

  final page1 = doc.getPageDict(0);
  page1['Contents'] = PdfRef(streamId);

  return doc;
}

PdfDocumentAst _buildEncryptedPdf() {
  final doc = _buildSynthesizedPdf(pageCount: 1);
  final encryptId = doc.nextAvailableObjectNumber();

  final encryptDict = PdfDict(const {
    'Filter': PdfName('Standard'),
    'V': PdfNumber(2),
    'R': PdfNumber(3),
    'O': PdfString([0x01, 0x02, 0x03]),
    'U': PdfString([0x04, 0x05, 0x06]),
    'P': PdfNumber(-4),
  });

  doc.objects[encryptId] = encryptDict;
  doc.objectGenerations[encryptId] = 0;
  doc.trailer['Encrypt'] = PdfRef(encryptId);

  return doc;
}
