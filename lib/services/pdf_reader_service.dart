import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfReaderService {
  static Future<String> readPdf(String path) async {
    final bytes = File(path).readAsBytesSync();

    final document = PdfDocument(inputBytes: bytes);

    final text = PdfTextExtractor(document).extractText();

    document.dispose();

    return text;
  }
}