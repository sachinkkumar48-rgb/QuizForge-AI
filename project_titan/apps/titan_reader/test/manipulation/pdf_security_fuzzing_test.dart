import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/pdf_manipulation_errors.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_tokenizer.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_manipulation_engine.dart';
import 'package:titan_reader/src/manipulation/services/pdf_document_manipulation_service.dart';

void main() {
  late Directory tempDir;
  const engine = DefaultPdfManipulationEngine();
  final service = PdfDocumentManipulationService(engine: engine);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_fuzzing_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6A.1: PDF Security & Malformed Document Fuzzing Tests', () {
    test('Zero byte file and tiny files (< 10 bytes) reject safely', () async {
      final emptyFile = File('${tempDir.path}/empty.pdf');
      await emptyFile.writeAsBytes([]);

      expect(
        () => service.inspectPageCount(emptyFile.path),
        throwsA(isA<Exception>()),
      );

      final tinyFile = File('${tempDir.path}/tiny.pdf');
      await tinyFile.writeAsBytes(utf8.encode('%PDF-1.4'));

      expect(
        () => service.inspectPageCount(tinyFile.path),
        throwsA(isA<Exception>()),
      );
    });

    test('Non-PDF file header (e.g. PNG / HTML / Random binary) rejects safely',
        () async {
      final pngFile = File('${tempDir.path}/fake.pdf');
      await pngFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

      expect(
        () => service.inspectPageCount(pngFile.path),
        throwsA(isA<Exception>()),
      );
    });

    test('Truncated PDF with missing trailer or missing objects fails safely',
        () async {
      final truncated = utf8.encode('''
%PDF-1.7
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages
''');
      final parser = PdfParser(Uint8List.fromList(truncated));
      expect(() => parser.parse(), throwsA(isA<PdfManipulationException>()));
    });

    test('Missing /Pages or corrupted catalog dictionary throws typed exception',
        () async {
      final badCatalog = utf8.encode('''
%PDF-1.7
1 0 obj
<< /Type /Catalog >>
endobj
trailer
<< /Root 1 0 R >>
%%EOF
''');
      final parser = PdfParser(Uint8List.fromList(badCatalog));
      expect(() => parser.parse(), throwsA(isA<PdfInvalidDocumentException>()));
    });

    test('Unclosed string and unclosed dictionary in tokenizer terminate safely',
        () {
      final unclosedStr = utf8.encode('(This string never ends');
      final tok1 = PdfTokenizer(Uint8List.fromList(unclosedStr));
      final obj1 = tok1.nextToken();
      expect(obj1, isA<PdfString>());
      expect((obj1 as PdfString).asString(), 'This string never ends');

      final unclosedDict = utf8.encode('<< /Key /Value');
      final tok2 = PdfTokenizer(Uint8List.fromList(unclosedDict));
      expect(tok2.nextToken(), '<<');
      expect(tok2.nextToken(), isA<PdfName>());
    });

    test('Deleting all pages in a document throws PdfEmptyDocumentResultException',
        () async {
      final validPdf = utf8.encode('''
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
trailer
<< /Root 1 0 R >>
%%EOF
''');
      final file = File('${tempDir.path}/one_page.pdf');
      await file.writeAsBytes(validPdf);

      expect(
        () => service.deletePages(
          sourcePath: file.path,
          pagesToDelete: [1],
        ),
        throwsA(isA<PdfEmptyDocumentResultException>()),
      );
    });

    test('Out of bounds page indices throw PdfPageRangeOutOfBoundsException',
        () async {
      final validPdf = utf8.encode('''
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
trailer
<< /Root 1 0 R >>
%%EOF
''');
      final file = File('${tempDir.path}/one_page_bounds.pdf');
      await file.writeAsBytes(validPdf);

      expect(
        () => service.extractPages(
          sourcePath: file.path,
          pages: [99],
        ),
        throwsA(isA<PdfPageRangeOutOfBoundsException>()),
      );

      expect(
        () => service.reorderPages(
          sourcePath: file.path,
          newOrder: [2],
        ),
        throwsA(isA<PdfPageRangeOutOfBoundsException>()),
      );
    });

    test('Duplicate page indices in reorder throws PdfManipulationException',
        () async {
      final validPdf = utf8.encode('''
%PDF-1.7
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R, 4 0 R] /Count 2 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>
endobj
4 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>
endobj
trailer
<< /Root 1 0 R >>
%%EOF
''');
      final file = File('${tempDir.path}/two_pages.pdf');
      await file.writeAsBytes(validPdf);

      expect(
        () => service.reorderPages(
          sourcePath: file.path,
          newOrder: [1, 1],
        ),
        throwsA(isA<PdfManipulationException>()),
      );
    });

    test('Deeply nested dictionary structures do not cause stack overflow',
        () {
      final sb = StringBuffer();
      for (var i = 0; i < 50; i++) {
        sb.write('<< /N ');
      }
      sb.write('42');
      for (var i = 0; i < 50; i++) {
        sb.write(' >>');
      }

      final tokenizer = PdfTokenizer(Uint8List.fromList(utf8.encode(sb.toString())));
      // Tokenizer handles nested delimiters without recursion
      expect(tokenizer.nextToken(), '<<');
    });
  });
}
