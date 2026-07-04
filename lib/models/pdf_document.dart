import 'dart:typed_data';

class PdfDocumentModel {
  final String fileName;
  final Uint8List bytes;

  const PdfDocumentModel({
    required this.fileName,
    required this.bytes,
  });

  int get sizeInBytes => bytes.lengthInBytes;

  bool get isEmpty => bytes.isEmpty;
}