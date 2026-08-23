import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/entities/normalized_page_rect.dart';
import '../domain/entities/ocr/ocr_result.dart';
import '../domain/entities/ocr/ocr_text_region.dart';
import '../domain/entities/pdf_searchable_export_result.dart';
import '../domain/pdf_manipulation_errors.dart';
import '../manipulation/ast/pdf_document_ast.dart';
import '../manipulation/ast/pdf_parser.dart';
import '../manipulation/ast/pdf_primitive.dart';
import '../manipulation/ast/pdf_writer.dart';

/// Application service generating standard searchable PDFs from OCR recognized text layers
/// while preserving original visual page appearance, dimensions, and source file integrity.
class PdfSearchableExportService {
  const PdfSearchableExportService();

  /// Pure coordinate transformation mapping normalized OCR coordinates (0.0 .. 1.0, top-down)
  /// to native PDF point coordinates (bottom-up ISO 32000-1 coordinate space) with optional page rotation.
  static ({
    double pdfX,
    double pdfY,
    double pdfWidth,
    double pdfHeight,
    double fontSize,
    double a,
    double b,
    double c,
    double d,
  }) transformCoordinates({
    required NormalizedPageRect rect,
    required double pageWidth,
    required double pageHeight,
    double lowerLeftX = 0.0,
    double lowerLeftY = 0.0,
    int rotation = 0,
  }) {
    final clampedRect = NormalizedPageRect(
      left: rect.left.clamp(0.0, 1.0),
      top: rect.top.clamp(0.0, 1.0),
      right: rect.right.clamp(0.0, 1.0),
      bottom: rect.bottom.clamp(0.0, 1.0),
    );

    final normalizedRotation = (rotation % 360 + 360) % 360;

    double pdfX;
    double pdfY;
    double boxWidth;
    double boxHeight;
    double a = 1.0;
    double b = 0.0;
    double c = 0.0;
    double d = 1.0;

    switch (normalizedRotation) {
      case 90:
        pdfX = lowerLeftX + (clampedRect.top * pageWidth);
        pdfY = lowerLeftY + (clampedRect.left * pageHeight);
        boxWidth = (clampedRect.bottom - clampedRect.top).clamp(0.0001, 1.0) *
            pageWidth;
        boxHeight = (clampedRect.right - clampedRect.left).clamp(0.0001, 1.0) *
            pageHeight;
        a = 0.0;
        b = -1.0;
        c = 1.0;
        d = 0.0;
        break;
      case 180:
        pdfX = lowerLeftX + ((1.0 - clampedRect.right) * pageWidth);
        pdfY = lowerLeftY + (clampedRect.top * pageHeight);
        boxWidth = (clampedRect.right - clampedRect.left).clamp(0.0001, 1.0) *
            pageWidth;
        boxHeight = (clampedRect.bottom - clampedRect.top).clamp(0.0001, 1.0) *
            pageHeight;
        a = -1.0;
        b = 0.0;
        c = 0.0;
        d = -1.0;
        break;
      case 270:
        pdfX = lowerLeftX + ((1.0 - clampedRect.bottom) * pageWidth);
        pdfY = lowerLeftY + ((1.0 - clampedRect.right) * pageHeight);
        boxWidth = (clampedRect.bottom - clampedRect.top).clamp(0.0001, 1.0) *
            pageWidth;
        boxHeight = (clampedRect.right - clampedRect.left).clamp(0.0001, 1.0) *
            pageHeight;
        a = 0.0;
        b = 1.0;
        c = -1.0;
        d = 0.0;
        break;
      case 0:
      default:
        pdfX = lowerLeftX + (clampedRect.left * pageWidth);
        pdfY = lowerLeftY + ((1.0 - clampedRect.bottom) * pageHeight);
        boxWidth = (clampedRect.right - clampedRect.left).clamp(0.0001, 1.0) *
            pageWidth;
        boxHeight = (clampedRect.bottom - clampedRect.top).clamp(0.0001, 1.0) *
            pageHeight;
        a = 1.0;
        b = 0.0;
        c = 0.0;
        d = 1.0;
        break;
    }

    final fontSize = boxHeight.clamp(1.0, 144.0);

    return (
      pdfX: pdfX,
      pdfY: pdfY,
      pdfWidth: boxWidth,
      pdfHeight: boxHeight,
      fontSize: fontSize,
      a: a,
      b: b,
      c: c,
      d: d,
    );
  }

  /// Sorts OCR words in deterministic natural reading order (top-to-bottom, left-to-right).
  static List<OcrWord> sortWordsInReadingOrder(List<OcrWord> words) {
    final list = List<OcrWord>.from(words);
    list.sort((a, b) {
      // Group words into lines if within ~1.5% vertical proximity
      final yDiff = (a.boundingBox.top - b.boundingBox.top).abs();
      if (yDiff > 0.015) {
        return a.boundingBox.top.compareTo(b.boundingBox.top);
      }
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });
    return list;
  }

  /// Escapes string literals for PDF content streams (ISO 32000-1 §7.3.4.2).
  static String escapePdfString(String text) {
    final sb = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '(') {
        sb.write(r'\(');
      } else if (char == ')') {
        sb.write(r'\)');
      } else if (char == r'\') {
        sb.write(r'\\');
      } else if (char == '\r') {
        sb.write(r'\r');
      } else if (char == '\n') {
        sb.write(r'\n');
      } else if (char == '\t') {
        sb.write(r'\t');
      } else {
        final code = char.codeUnitAt(0);
        if (code >= 32 && code <= 126) {
          sb.write(char);
        } else if (code >= 128 && code <= 255) {
          final octal = code.toRadixString(8).padLeft(3, '0');
          sb.write('\\$octal');
        } else {
          sb.write('?');
        }
      }
    }
    return sb.toString();
  }

  /// Exports a new searchable PDF by injecting invisible OCR text layers into [outputPath].
  ///
  /// The [inputPath] file is opened in read-only mode and is guaranteed never to be mutated.
  Future<PdfSearchableExportResult> exportSearchablePdf({
    required String inputPath,
    required String outputPath,
    required Map<int, OcrResult> pageOcrResults,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final sw = Stopwatch()..start();
    try {
      if (inputPath == outputPath) {
        return PdfSearchableExportResult.failed(
          errorMessage: 'Output path cannot overwrite input source PDF.',
          elapsed: sw.elapsed,
        );
      }

      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        return PdfSearchableExportResult.invalidDocument(
          message: 'Source PDF file does not exist: $inputPath',
        );
      }

      final bytes = await inputFile.readAsBytes();
      if (bytes.isEmpty) {
        return PdfSearchableExportResult.invalidDocument(
          message: 'Source PDF file is empty.',
        );
      }

      final parser = PdfParser(bytes);
      final ast = parser.parse();

      if (ast.trailer.containsKey('Encrypt') ||
          ast.catalog.containsKey('Encrypt')) {
        return PdfSearchableExportResult.encrypted(
          totalPagesCount: ast.pageCount,
        );
      }

      if (pageOcrResults.isEmpty) {
        return PdfSearchableExportResult.noOcrData(
          totalPagesCount: ast.pageCount,
        );
      }

      var exportedPages = 0;
      final totalPages = ast.pageCount;

      for (var pageIdx = 0; pageIdx < totalPages; pageIdx++) {
        if (isCancelled?.call() == true) {
          return PdfSearchableExportResult.cancelled(elapsed: sw.elapsed);
        }

        final pageNum = pageIdx + 1;
        final ocrResult = pageOcrResults[pageNum];
        if (ocrResult != null &&
            ocrResult.isSuccess &&
            ocrResult.words.isNotEmpty) {
          _injectSearchableTextLayer(ast, pageIdx, ocrResult);
          exportedPages++;
        }

        onProgress?.call((pageIdx + 1) / totalPages);
      }

      if (exportedPages == 0) {
        return PdfSearchableExportResult.noOcrData(
          totalPagesCount: totalPages,
          message: 'No valid OCR words found on any page for export.',
        );
      }

      final writer = PdfWriter(ast);
      final outFile = await writer.writeAtomic(outputPath);
      sw.stop();

      return PdfSearchableExportResult.success(
        outputPath: outFile.path,
        exportedPagesCount: exportedPages,
        totalPagesCount: totalPages,
        fileSizeBytes: await outFile.length(),
        elapsed: sw.elapsed,
      );
    } on PdfUnsupportedDocumentException catch (e) {
      sw.stop();
      if (e.reason.contains('Encrypted') || e.message.contains('Encrypted')) {
        return PdfSearchableExportResult.encrypted(
          elapsed: sw.elapsed,
        );
      }
      return PdfSearchableExportResult.unsupported(
        reason: e.reason,
        elapsed: sw.elapsed,
      );
    } on PdfInvalidDocumentException catch (e) {
      sw.stop();
      return PdfSearchableExportResult.invalidDocument(
        message: e.message,
        elapsed: sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      return PdfSearchableExportResult.failed(
        errorMessage: 'Searchable PDF export failed: $e',
        elapsed: sw.elapsed,
      );
    }
  }

  void _injectSearchableTextLayer(
    PdfDocumentAst ast,
    int pageIdx,
    OcrResult ocrResult,
  ) {
    if (pageIdx < 0 || pageIdx >= ast.pageRefs.length) return;

    final pageRef = ast.pageRefs[pageIdx];
    final pageObj = ast.objects[pageRef.objectNumber];
    if (pageObj is! PdfDict) return;
    final pageDict = pageObj;

    // 1. Resolve Page Geometry (MediaBox / CropBox)
    final mediaBox = pageDict.getArray('MediaBox') ??
        pageDict.getArray('CropBox') ??
        PdfArray(const [
          PdfNumber(0),
          PdfNumber(0),
          PdfNumber(595.28),
          PdfNumber(841.89)
        ]);

    final llx = mediaBox.items.isNotEmpty && mediaBox.items[0] is PdfNumber
        ? (mediaBox.items[0] as PdfNumber).asDouble
        : 0.0;
    final lly = mediaBox.items.length > 1 && mediaBox.items[1] is PdfNumber
        ? (mediaBox.items[1] as PdfNumber).asDouble
        : 0.0;
    final urx = mediaBox.items.length > 2 && mediaBox.items[2] is PdfNumber
        ? (mediaBox.items[2] as PdfNumber).asDouble
        : 595.28;
    final ury = mediaBox.items.length > 3 && mediaBox.items[3] is PdfNumber
        ? (mediaBox.items[3] as PdfNumber).asDouble
        : 841.89;

    final pageWidth = (urx - llx).abs();
    final pageHeight = (ury - lly).abs();
    final rotateObj = pageDict['Rotate'];
    final pageRotation = rotateObj is PdfNumber ? rotateObj.asInt : 0;

    // 2. Ensure Standard Font Resource Attached
    final fontRef = _ensureFontResource(ast, pageDict);

    // 3. Build Invisible Text Content Stream
    final streamBuffer = StringBuffer();
    streamBuffer.writeln('BT');
    streamBuffer.writeln('3 Tr'); // Invisible text mode (ISO 32000-1 §9.3.5)

    final sortedWords = sortWordsInReadingOrder(ocrResult.words);

    for (final word in sortedWords) {
      if (word.text.trim().isEmpty) continue;

      final coords = transformCoordinates(
        rect: word.boundingBox,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        lowerLeftX: llx,
        lowerLeftY: lly,
        rotation: pageRotation,
      );

      final escaped = escapePdfString(word.text);
      streamBuffer
          .writeln('/$fontRef ${coords.fontSize.toStringAsFixed(2)} Tf');
      streamBuffer.writeln(
          '${coords.a.toStringAsFixed(2)} ${coords.b.toStringAsFixed(2)} ${coords.c.toStringAsFixed(2)} ${coords.d.toStringAsFixed(2)} ${coords.pdfX.toStringAsFixed(2)} ${coords.pdfY.toStringAsFixed(2)} Tm');
      streamBuffer.writeln('($escaped) Tj');
    }

    streamBuffer.writeln('ET');

    // 4. Append Text Stream to Page Contents
    _appendStreamToPageContents(ast, pageDict, streamBuffer.toString());
  }

  String _ensureFontResource(PdfDocumentAst ast, PdfDict pageDict) {
    PdfDict resources;
    final resObj = pageDict['Resources'];
    if (resObj is PdfDict) {
      resources = resObj;
    } else if (resObj is PdfRef) {
      final resolved = ast.objects[resObj.objectNumber];
      if (resolved is PdfDict) {
        resources = resolved;
      } else {
        resources = PdfDict();
        pageDict['Resources'] = resources;
      }
    } else {
      resources = PdfDict();
      pageDict['Resources'] = resources;
    }

    PdfDict fontsDict;
    final fontsObj = resources['Font'];
    if (fontsObj is PdfDict) {
      fontsDict = fontsObj;
    } else if (fontsObj is PdfRef) {
      final resolved = ast.objects[fontsObj.objectNumber];
      if (resolved is PdfDict) {
        fontsDict = resolved;
      } else {
        fontsDict = PdfDict();
        resources['Font'] = fontsDict;
      }
    } else {
      fontsDict = PdfDict();
      resources['Font'] = fontsDict;
    }

    const fontKey = 'F_OCR';
    if (!fontsDict.containsKey(fontKey)) {
      final fontObjNum = ast.nextAvailableObjectNumber();
      ast.objects[fontObjNum] = PdfDict(const {
        'Type': PdfName('Font'),
        'Subtype': PdfName('Type1'),
        'BaseFont': PdfName('Helvetica'),
        'Encoding': PdfName('WinAnsiEncoding'),
      });
      ast.objectGenerations[fontObjNum] = 0;
      fontsDict[fontKey] = PdfRef(fontObjNum);
    }

    return fontKey;
  }

  void _appendStreamToPageContents(
    PdfDocumentAst ast,
    PdfDict pageDict,
    String textOps,
  ) {
    final textBytes = utf8.encode('\n$textOps\n');
    final newStreamNum = ast.nextAvailableObjectNumber();
    final newStream = PdfStream(
      dict: PdfDict({'Length': PdfNumber(textBytes.length)}),
      data: Uint8List.fromList(textBytes),
    );
    ast.objects[newStreamNum] = newStream;
    ast.objectGenerations[newStreamNum] = 0;

    final contentsRef = pageDict['Contents'];
    if (contentsRef is PdfArray) {
      contentsRef.add(PdfRef(newStreamNum));
    } else if (contentsRef is PdfRef) {
      pageDict['Contents'] = PdfArray([contentsRef, PdfRef(newStreamNum)]);
    } else {
      pageDict['Contents'] = PdfRef(newStreamNum);
    }
  }
}
