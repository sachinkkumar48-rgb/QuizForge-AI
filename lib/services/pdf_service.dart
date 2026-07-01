import 'package:file_picker/file_picker.dart';

class PdfService {
  static Future<String?> pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      return result.files.single.path;
    }

    return null;
  }
}