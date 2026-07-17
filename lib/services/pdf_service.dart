import 'package:file_picker/file_picker.dart';

class PdfService {
  PdfService._();

  static Future<PlatformFile?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.first;
  }
}
