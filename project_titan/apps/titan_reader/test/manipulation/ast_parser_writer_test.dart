import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_tokenizer.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';

void main() {
  group('Phase 6A: PDF Primitives Serialization Tests', () {
    test('PdfNull serializes correctly', () {
      final builder = BytesBuilder();
      const PdfNull().writeTo(builder);
      expect(utf8.decode(builder.takeBytes()), 'null');
    });

    test('PdfBoolean serializes correctly', () {
      final b1 = BytesBuilder();
      const PdfBoolean(true).writeTo(b1);
      expect(utf8.decode(b1.takeBytes()), 'true');

      final b2 = BytesBuilder();
      const PdfBoolean(false).writeTo(b2);
      expect(utf8.decode(b2.takeBytes()), 'false');
    });

    test('PdfNumber serializes ints and reals', () {
      final b1 = BytesBuilder();
      const PdfNumber(42).writeTo(b1);
      expect(utf8.decode(b1.takeBytes()), '42');

      final b2 = BytesBuilder();
      const PdfNumber(3.14).writeTo(b2);
      expect(utf8.decode(b2.takeBytes()), '3.14');
    });

    test('PdfName serializes with leading slash and escapes', () {
      final b1 = BytesBuilder();
      const PdfName('Type').writeTo(b1);
      expect(utf8.decode(b1.takeBytes()), '/Type');

      final b2 = BytesBuilder();
      const PdfName('Page#1').writeTo(b2);
      expect(utf8.decode(b2.takeBytes()), '/Page#231');
    });

    test('PdfString serializes literals and hex', () {
      final b1 = BytesBuilder();
      PdfString.fromString('Hello (World)').writeTo(b1);
      expect(utf8.decode(b1.takeBytes()), r'(Hello \(World\))');

      final b2 = BytesBuilder();
      PdfString.fromString('AB', isHex: true).writeTo(b2);
      expect(utf8.decode(b2.takeBytes()), '<4142>');
    });

    test('PdfRef serializes as X Y R', () {
      final builder = BytesBuilder();
      const PdfRef(10, 0).writeTo(builder);
      expect(utf8.decode(builder.takeBytes()), '10 0 R');
    });

    test('PdfArray and PdfDict serialize structure', () {
      final array = PdfArray(const [PdfNumber(1), PdfName('A'), PdfRef(5, 0)]);
      final b1 = BytesBuilder();
      array.writeTo(b1);
      expect(utf8.decode(b1.takeBytes()), '[1 /A 5 0 R]');

      final dict = PdfDict(const {
        'Type': PdfName('Catalog'),
        'Pages': PdfRef(2, 0),
      });
      final b2 = BytesBuilder();
      dict.writeTo(b2);
      expect(utf8.decode(b2.takeBytes()), '<</Type /Catalog /Pages 2 0 R>>');
    });
  });

  group('Phase 6A: PDF Tokenizer Tests', () {
    test('PdfTokenizer handles comments, whitespace, and tokens', () {
      const raw = '''
      % Sample PDF comment
      << /Type /Page /Rotate 90 /Kids [ 1 0 R 2 0 R ] >>
      ''';
      final tokenizer = PdfTokenizer(Uint8List.fromList(utf8.encode(raw)));
      expect(tokenizer.nextToken(), '<<');
      expect(tokenizer.nextToken(), const PdfName('Type'));
      expect(tokenizer.nextToken(), const PdfName('Page'));
      expect(tokenizer.nextToken(), const PdfName('Rotate'));
      expect(tokenizer.nextToken(), const PdfNumber(90));
      expect(tokenizer.nextToken(), const PdfName('Kids'));
      expect(tokenizer.nextToken(), '[');
      expect(tokenizer.nextToken(), const PdfNumber(1));
      expect(tokenizer.nextToken(), const PdfNumber(0));
      expect(tokenizer.nextToken(), 'R');
      expect(tokenizer.nextToken(), const PdfNumber(2));
      expect(tokenizer.nextToken(), const PdfNumber(0));
      expect(tokenizer.nextToken(), 'R');
      expect(tokenizer.nextToken(), ']');
      expect(tokenizer.nextToken(), '>>');
    });
  });

  group('Phase 6A: PDF Parser & Writer Round-Trip Tests', () {
    test('Constructs, writes, parses, and modifies minimal valid PDF', () {
      // 1. Synthesize minimal PDF AST
      final objects = <int, PdfObject>{};
      final gens = <int, int>{};

      final catalog = PdfDict(const {
        'Type': PdfName('Catalog'),
        'Pages': PdfRef(2),
      });
      final pages = PdfDict({
        'Type': const PdfName('Pages'),
        'Kids': PdfArray(const [PdfRef(3), PdfRef(4)]),
        'Count': const PdfNumber(2),
      });
      final page1 = PdfDict({
        'Type': const PdfName('Page'),
        'Parent': const PdfRef(2),
        'MediaBox': PdfArray(const [
          PdfNumber(0),
          PdfNumber(0),
          PdfNumber(612),
          PdfNumber(792),
        ]),
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

      objects[1] = catalog;
      gens[1] = 0;
      objects[2] = pages;
      gens[2] = 0;
      objects[3] = page1;
      gens[3] = 0;
      objects[4] = page2;
      gens[4] = 0;

      final trailer = PdfDict(const {
        'Root': PdfRef(1),
      });

      final docAst = PdfDocumentAst(
        header: '%PDF-1.7',
        objects: objects,
        objectGenerations: gens,
        trailer: trailer,
        catalog: catalog,
      );

      expect(docAst.pageCount, 2);

      // 2. Write to bytes
      final writer = PdfWriter(docAst);
      final pdfBytes = writer.writeBytes();
      expect(pdfBytes.length, greaterThan(100));

      // 3. Parse back with PdfParser
      final parser = PdfParser(pdfBytes);
      final parsedAst = parser.parse();

      expect(parsedAst.pageCount, 2);
      expect(parsedAst.catalog.getName('Type'), 'Catalog');

      // 4. Test in-memory mutations
      parsedAst.rotatePage(0, 90);
      expect(parsedAst.getPageDict(0).getInt('Rotate'), 90);

      parsedAst.insertBlankPage(1);
      expect(parsedAst.pageCount, 3);

      parsedAst.reorderPages([2, 0, 1]);
      expect(parsedAst.pageCount, 3);

      parsedAst.deletePages([0]);
      expect(parsedAst.pageCount, 2);
    });
  });
}
