import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfReaderService {
  PdfReaderService._();

  static Future<String> readPdf(PlatformFile file) async {
    if (file.bytes == null) {
      throw Exception(
        kIsWeb
            ? "Unable to read PDF bytes in the browser."
            : "PDF bytes are unavailable. Please reselect the PDF.",
      );
    }

    try {
      final document = PdfDocument(
        inputBytes: file.bytes!,
      );

      try {
        return PdfTextExtractor(document).extractText().trim();
      } finally {
        document.dispose();
      }
    } catch (e) {
      throw Exception(
        "Failed to parse the selected PDF. The file may be corrupted, encrypted, or password-protected.",
      );
    }
  }
}
