import 'dart:io';
import 'dart:typed_data';

import '../domain/entities/pdf_embedded_file.dart';
import '../domain/entities/pdf_filename_sanitizer.dart';
import '../manipulation/ast/pdf_attachment_parser.dart';
import '../manipulation/ast/pdf_document_ast.dart';
import '../manipulation/ast/pdf_parser.dart';

/// Application service managing the discovery, inspection, and safe extraction of embedded PDF files.
class PdfAttachmentService {
  final Future<bool> Function(String filePath)? _fileExists;
  final Future<Uint8List> Function(String filePath)? _readFileBytes;

  const PdfAttachmentService({
    Future<bool> Function(String filePath)? fileExists,
    Future<Uint8List> Function(String filePath)? readFileBytes,
  })  : _fileExists = fileExists,
        _readFileBytes = readFileBytes;

  /// Discovers and lists all embedded file attachments inside the PDF at [filePath].
  Future<List<PdfEmbeddedFile>> listAttachments(
      {required String filePath}) async {
    if (filePath.trim().isEmpty) return const [];

    final exists = _fileExists != null
        ? await _fileExists(filePath)
        : await File(filePath).exists();
    if (!exists) return const [];

    try {
      final bytes = _readFileBytes != null
          ? await _readFileBytes(filePath)
          : await File(filePath).readAsBytes();

      final parser = PdfParser(bytes);
      final ast = parser.parse();
      final attachmentParser = PdfAttachmentParser(ast);
      return attachmentParser.parseAllAttachments();
    } catch (_) {
      return const [];
    }
  }

  /// Discovers and lists all embedded file attachments directly from an in-memory [PdfDocumentAst].
  List<PdfEmbeddedFile> listAttachmentsFromAst(PdfDocumentAst ast) {
    try {
      final attachmentParser = PdfAttachmentParser(ast);
      return attachmentParser.parseAllAttachments();
    } catch (_) {
      return const [];
    }
  }

  /// Extracts a single [attachment] from [sourceFilePath] and writes it safely into [targetDirectoryPath].
  ///
  /// The extracted file is NEVER automatically executed.
  Future<PdfAttachmentExtractionResult> extractAttachment({
    required String sourceFilePath,
    required PdfEmbeddedFile attachment,
    required String targetDirectoryPath,
    bool overwrite = false,
  }) async {
    if (sourceFilePath.trim().isEmpty) {
      return PdfAttachmentExtractionResult.failed(
          'Source PDF file path cannot be empty.');
    }
    if (targetDirectoryPath.trim().isEmpty) {
      return PdfAttachmentExtractionResult.failed(
          'Target extraction directory cannot be empty.');
    }

    final exists = _fileExists != null
        ? await _fileExists(sourceFilePath)
        : await File(sourceFilePath).exists();
    if (!exists) {
      return PdfAttachmentExtractionResult.failed(
          'Source PDF file not found at: $sourceFilePath');
    }

    try {
      final bytes = _readFileBytes != null
          ? await _readFileBytes(sourceFilePath)
          : await File(sourceFilePath).readAsBytes();

      final parser = PdfParser(bytes);
      final ast = parser.parse();
      final attachmentParser = PdfAttachmentParser(ast);

      final payloadBytes = attachmentParser.extractAttachmentBytes(attachment);

      final targetPath = PdfFilenameSanitizer.resolveSafeDestinationPath(
        destinationDirectoryPath: targetDirectoryPath,
        desiredFilename: attachment.filename,
        overwrite: overwrite,
      );

      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(payloadBytes, flush: true);

      return PdfAttachmentExtractionResult.completed(
        outputPath: targetPath,
        extractedBytesCount: payloadBytes.length,
      );
    } catch (e) {
      return PdfAttachmentExtractionResult.failed(
          'Failed to extract attachment: $e');
    }
  }

  /// Extracts all embedded attachments from [sourceFilePath] into [targetDirectoryPath].
  Future<List<PdfAttachmentExtractionResult>> extractAllAttachments({
    required String sourceFilePath,
    required String targetDirectoryPath,
    bool overwrite = false,
  }) async {
    final attachments = await listAttachments(filePath: sourceFilePath);
    if (attachments.isEmpty) return const [];

    final results = <PdfAttachmentExtractionResult>[];
    for (final attachment in attachments) {
      final res = await extractAttachment(
        sourceFilePath: sourceFilePath,
        attachment: attachment,
        targetDirectoryPath: targetDirectoryPath,
        overwrite: overwrite,
      );
      results.add(res);
    }
    return results;
  }
}
