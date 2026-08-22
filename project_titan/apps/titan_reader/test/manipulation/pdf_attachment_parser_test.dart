import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_embedded_file.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_attachment_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';

void main() {
  group('PdfAttachmentParser AST Discovery & Extraction Tests', () {
    test(
        'discovers document-level embedded files in /Names /EmbeddedFiles name tree',
        () {
      final ast = _createAstWithCatalogEmbeddedFiles();
      final parser = PdfAttachmentParser(ast);

      final attachments = parser.parseAllAttachments();
      expect(attachments.length, 1);

      final att = attachments.first;
      expect(att.filename, 'attachment1.txt');
      expect(att.unicodeFilename, 'attachment1.txt');
      expect(att.description, 'Sample text payload');
      expect(att.mimeType, 'text/plain');
      expect(att.declaredSize, 21);
      expect(att.sourceLocation, PdfAttachmentSourceLocation.documentLevel);

      // Verify stream byte extraction and decompression
      final bytes = parser.extractAttachmentBytes(att);
      expect(utf8.decode(bytes), 'Hello Embedded World!');
    });

    test('discovers hierarchical name tree embedded files with /Kids', () {
      final ast = _createAstWithHierarchicalNameTree();
      final parser = PdfAttachmentParser(ast);

      final attachments = parser.parseAllAttachments();
      expect(attachments.length, 2);
      expect(attachments.map((a) => a.filename),
          containsAll(['file_a.txt', 'file_b.txt']));
    });

    test('discovers Associated Files in Catalog /AF (PDF/A-3 & PDF 2.0)', () {
      final ast = _createAstWithAssociatedFiles();
      final parser = PdfAttachmentParser(ast);

      final attachments = parser.parseAllAttachments();
      expect(attachments.length, 1);

      final att = attachments.first;
      expect(att.filename, 'dataset.csv');
      expect(att.relationship, 'Data');
      expect(att.mimeType, 'text/csv');

      final bytes = parser.extractAttachmentBytes(att);
      expect(utf8.decode(bytes), 'id,value\n1,100\n2,200\n');
    });

    test(
        'discovers page-level file attachment annotations (/Annots /FileAttachment)',
        () {
      final ast = _createAstWithPageAnnotationAttachment();
      final parser = PdfAttachmentParser(ast);

      final attachments = parser.parseAllAttachments();
      expect(attachments.length, 1);

      final att = attachments.first;
      expect(att.filename, 'annot_graphic.png');
      expect(att.sourceLocation, PdfAttachmentSourceLocation.annotation);
      expect(att.pageNumber, 1);
      expect(att.mimeType, 'image/png');
    });

    test(
        'safely handles uncompressed raw streams and corrupt compressed streams',
        () {
      final rawData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final objects = <int, PdfObject>{
        10: PdfStream(
          dict: PdfDict(const {'Type': PdfName('EmbeddedFile')}),
          data: rawData,
        ),
      };

      final ast = PdfDocumentAst(
        header: '%PDF-1.7',
        objects: objects,
        objectGenerations: const {10: 0},
        trailer: PdfDict(),
        catalog: _createBaseCatalog(),
      );

      final parser = PdfAttachmentParser(ast);
      const file = PdfEmbeddedFile(
        id: '10',
        filename: 'raw.bin',
        streamObjectNumber: 10,
      );

      final extracted = parser.extractAttachmentBytes(file);
      expect(extracted, equals(rawData));
    });
  });
}

PdfDict _createBaseCatalog() {
  return PdfDict({
    'Type': const PdfName('Catalog'),
    'Pages': PdfDict({
      'Type': const PdfName('Pages'),
      'Kids': PdfArray([
        PdfDict({
          'Type': const PdfName('Page'),
          'MediaBox': PdfArray(const [
            PdfNumber(0),
            PdfNumber(0),
            PdfNumber(612),
            PdfNumber(792),
          ]),
        }),
      ]),
      'Count': const PdfNumber(1),
    }),
  });
}

PdfDocumentAst _createAstWithCatalogEmbeddedFiles() {
  final content = utf8.encode('Hello Embedded World!');
  final compressed = Uint8List.fromList(zlib.encode(content));

  final streamDict = PdfDict({
    'Type': const PdfName('EmbeddedFile'),
    'Subtype': const PdfName('text#2Fplain'),
    'Filter': const PdfName('FlateDecode'),
    'Params': PdfDict({
      'Size': PdfNumber(content.length),
      'CreationDate': PdfString.fromString('D:20260822120000'),
    }),
  });

  final fileSpecDict = PdfDict({
    'Type': const PdfName('Filespec'),
    'F': PdfString.fromString('attachment1.txt'),
    'UF': PdfString.fromString('attachment1.txt'),
    'Desc': PdfString.fromString('Sample text payload'),
    'EF': PdfDict(const {'F': PdfRef(10), 'UF': PdfRef(10)}),
  });

  final embeddedFilesTree = PdfDict({
    'Names': PdfArray([
      PdfString.fromString('attachment1.txt'),
      const PdfRef(9),
    ]),
  });

  final namesDict = PdfDict(const {
    'EmbeddedFiles': PdfRef(8),
  });

  final catalog = _createBaseCatalog();
  catalog['Names'] = const PdfRef(7);

  final objects = <int, PdfObject>{
    7: namesDict,
    8: embeddedFilesTree,
    9: fileSpecDict,
    10: PdfStream(dict: streamDict, data: compressed),
  };

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: const {7: 0, 8: 0, 9: 0, 10: 0},
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}

PdfDocumentAst _createAstWithHierarchicalNameTree() {
  final contentA = Uint8List.fromList(utf8.encode('File A'));
  final contentB = Uint8List.fromList(utf8.encode('File B'));

  final streamA = PdfStream(
    dict: PdfDict(const {'Type': PdfName('EmbeddedFile')}),
    data: contentA,
  );
  final streamB = PdfStream(
    dict: PdfDict(const {'Type': PdfName('EmbeddedFile')}),
    data: contentB,
  );

  final specA = PdfDict({
    'Type': const PdfName('Filespec'),
    'UF': PdfString.fromString('file_a.txt'),
    'EF': PdfDict(const {'UF': PdfRef(21)}),
  });

  final specB = PdfDict({
    'Type': const PdfName('Filespec'),
    'UF': PdfString.fromString('file_b.txt'),
    'EF': PdfDict(const {'UF': PdfRef(22)}),
  });

  final leaf1 = PdfDict({
    'Names': PdfArray([PdfString.fromString('file_a'), const PdfRef(11)]),
  });
  final leaf2 = PdfDict({
    'Names': PdfArray([PdfString.fromString('file_b'), const PdfRef(12)]),
  });

  final rootTree = PdfDict({
    'Kids': PdfArray(const [PdfRef(31), PdfRef(32)]),
  });

  final namesDict = PdfDict(const {'EmbeddedFiles': PdfRef(30)});
  final catalog = _createBaseCatalog();
  catalog['Names'] = namesDict;

  final objects = <int, PdfObject>{
    11: specA,
    12: specB,
    21: streamA,
    22: streamB,
    30: rootTree,
    31: leaf1,
    32: leaf2,
  };

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: const {11: 0, 12: 0, 21: 0, 22: 0, 30: 0, 31: 0, 32: 0},
    trailer: PdfDict(),
    catalog: catalog,
  );
}

PdfDocumentAst _createAstWithAssociatedFiles() {
  final content = Uint8List.fromList(utf8.encode('id,value\n1,100\n2,200\n'));

  final streamObj = PdfStream(
    dict: PdfDict(const {
      'Type': PdfName('EmbeddedFile'),
      'Subtype': PdfName('text#2Fcsv'),
    }),
    data: content,
  );

  final spec = PdfDict({
    'Type': const PdfName('Filespec'),
    'UF': PdfString.fromString('dataset.csv'),
    'AFRelationship': const PdfName('Data'),
    'EF': PdfDict(const {'UF': PdfRef(51)}),
  });

  final catalog = _createBaseCatalog();
  catalog['AF'] = PdfArray(const [PdfRef(50)]);

  final objects = <int, PdfObject>{
    50: spec,
    51: streamObj,
  };

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: const {50: 0, 51: 0},
    trailer: PdfDict(),
    catalog: catalog,
  );
}

PdfDocumentAst _createAstWithPageAnnotationAttachment() {
  final pngBytes =
      Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG signature

  final streamObj = PdfStream(
    dict: PdfDict(const {
      'Type': PdfName('EmbeddedFile'),
      'Subtype': PdfName('image#2Fpng'),
    }),
    data: pngBytes,
  );

  final spec = PdfDict({
    'Type': const PdfName('Filespec'),
    'UF': PdfString.fromString('annot_graphic.png'),
    'EF': PdfDict(const {'UF': PdfRef(61)}),
  });

  final annotDict = PdfDict({
    'Type': const PdfName('Annot'),
    'Subtype': const PdfName('FileAttachment'),
    'FS': const PdfRef(60),
    'Rect': PdfArray(const [
      PdfNumber(100),
      PdfNumber(100),
      PdfNumber(150),
      PdfNumber(150),
    ]),
  });

  final pageDict = PdfDict({
    'Type': const PdfName('Page'),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
    'Annots': PdfArray(const [PdfRef(70)]),
  });

  final pagesDict = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(80)]),
    'Count': const PdfNumber(1),
  });

  final catalog = PdfDict(const {
    'Type': PdfName('Catalog'),
    'Pages': PdfRef(90),
  });

  final objects = <int, PdfObject>{
    60: spec,
    61: streamObj,
    70: annotDict,
    80: pageDict,
    90: pagesDict,
  };

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: const {60: 0, 61: 0, 70: 0, 80: 0, 90: 0},
    trailer: PdfDict(),
    catalog: catalog,
  );
}
