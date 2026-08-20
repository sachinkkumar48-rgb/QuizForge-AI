import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'pdf_primitive.dart';
import 'pdf_document_ast.dart';
import '../../domain/pdf_manipulation_errors.dart';

/// Serializes [PdfDocumentAst] into valid ISO 32000-1 binary PDF byte streams with atomic file safety.
class PdfWriter {
  final PdfDocumentAst document;

  PdfWriter(this.document);

  /// Generates the complete binary PDF bytes.
  Uint8List writeBytes() {
    final builder = BytesBuilder(copy: false);

    // 1. Header
    final headerStr = document.header.isNotEmpty ? document.header : '%PDF-1.7';
    builder.add(utf8.encode('$headerStr\n%âãÏÓ\n'));

    // 2. Objects Body
    final sortedObjectIds = document.objects.keys.toList()..sort();
    final maxObjId = sortedObjectIds.isNotEmpty ? sortedObjectIds.last : 0;
    final offsets = <int, int>{};

    for (final objId in sortedObjectIds) {
      final obj = document.objects[objId]!;
      final gen = document.objectGenerations[objId] ?? 0;

      offsets[objId] = builder.length;
      builder.add(utf8.encode('$objId $gen obj\n'));
      obj.writeTo(builder);
      builder.add(const [
        0x0A,
        0x65,
        0x6E,
        0x64,
        0x6F,
        0x62,
        0x6A,
        0x0A
      ]); // '\nendobj\n'
    }

    // 3. Cross-Reference Table (xref)
    final startXrefOffset = builder.length;
    final totalSize = maxObjId + 1;

    builder.add(utf8.encode('xref\n0 $totalSize\n'));
    builder.add(utf8.encode('0000000000 65535 f \n'));

    for (var i = 1; i <= maxObjId; i++) {
      final offset = offsets[i];
      if (offset != null) {
        final gen =
            (document.objectGenerations[i] ?? 0).toString().padLeft(5, '0');
        final offStr = offset.toString().padLeft(10, '0');
        builder.add(utf8.encode('$offStr $gen n \n'));
      } else {
        builder.add(utf8.encode('0000000000 65535 f \n'));
      }
    }

    // 4. Trailer Dictionary
    final trailerDict = document.trailer;
    trailerDict['Size'] = PdfNumber(totalSize);
    builder.add(utf8.encode('trailer\n'));
    trailerDict.writeTo(builder);
    builder.add(const [0x0A]);

    // 5. startxref & %%EOF
    builder.add(utf8.encode('startxref\n$startXrefOffset\n%%EOF\n'));

    return builder.takeBytes();
  }

  /// Writes output to [targetPath] atomically via temporary staging file.
  Future<File> writeAtomic(String targetPath) async {
    try {
      final targetFile = File(targetPath);
      final parentDir = targetFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final tmpPath =
          '$targetPath.tmp_titan_${DateTime.now().microsecondsSinceEpoch}';
      final tmpFile = File(tmpPath);

      final bytes = writeBytes();
      await tmpFile.writeAsBytes(bytes, flush: true);

      // Verify file was written
      if (!await tmpFile.exists() || await tmpFile.length() < 10) {
        throw PdfAtomicWriteException(
            'Temporary staging file failed validation: $tmpPath',
            targetPath: targetPath);
      }

      // Atomic rename / replace
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      return await tmpFile.rename(targetPath);
    } catch (e) {
      if (e is PdfManipulationException) rethrow;
      throw PdfAtomicWriteException(
          'Failed to write output PDF to $targetPath: $e',
          targetPath: targetPath,
          cause: e);
    }
  }
}
