import 'dart:io';
import 'dart:typed_data';

import '../domain/entities/pdf_encryption_options.dart';
import '../domain/entities/pdf_encryption_result.dart';
import '../manipulation/ast/pdf_document_ast.dart';
import '../manipulation/ast/pdf_parser.dart';
import '../manipulation/ast/pdf_primitive.dart';
import '../manipulation/ast/pdf_writer.dart';
import '../manipulation/crypto/pdf_crypto_primitives.dart';
import '../manipulation/crypto/pdf_standard_security_handler.dart';

/// Production application service managing PDF password protection and encryption workflows.
class PdfEncryptionService {
  final Future<bool> Function(String filePath)? _fileExists;

  const PdfEncryptionService({
    Future<bool> Function(String filePath)? fileExists,
  }) : _fileExists = fileExists;

  /// Encrypts the PDF at [sourceFilePath] with the supplied [config] and saves to [targetFilePath].
  ///
  /// The original unencrypted file is preserved untouched.
  Future<PdfEncryptionResult> encryptPdfFile({
    required String sourceFilePath,
    required String targetFilePath,
    required PdfEncryptionConfig config,
  }) async {
    if (sourceFilePath.trim().isEmpty) {
      return PdfEncryptionResult.failed(
          'Source PDF file path cannot be empty.');
    }
    if (targetFilePath.trim().isEmpty) {
      return PdfEncryptionResult.failed(
          'Target PDF file path cannot be empty.');
    }
    if (!config.hasPassword) {
      return PdfEncryptionResult.failed(
          'Cannot protect document: at least a user or owner password is required.');
    }

    final exists = _fileExists != null
        ? await _fileExists(sourceFilePath)
        : await File(sourceFilePath).exists();
    if (!exists) {
      return PdfEncryptionResult.failed(
          'Source PDF file not found at: $sourceFilePath');
    }

    try {
      final sourceBytes = await File(sourceFilePath).readAsBytes();
      final parser = PdfParser(sourceBytes);
      final ast = parser.parse();

      // 1. Resolve or generate 16-byte File Identifier
      final fileId = _resolveFileId(ast);

      // 2. Initialize Standard Security Handler
      final handler = PdfStandardSecurityHandler(
        config: config,
        fileId: fileId,
      );

      // 3. Allocate fresh Object ID for /Encrypt dictionary
      final encryptObjId = ast.nextAvailableObjectNumber();

      // 4. Encrypt AST objects (streams and strings)
      final encryptedObjects = <int, PdfObject>{};
      for (final entry in ast.objects.entries) {
        final objId = entry.key;
        final gen = ast.objectGenerations[objId] ?? 0;
        final obj = entry.value;

        // Do not encrypt the /Encrypt object itself
        if (objId == encryptObjId) continue;

        encryptedObjects[objId] = _encryptPdfObject(
          obj: obj,
          objId: objId,
          gen: gen,
          handler: handler,
        );
      }

      ast.objects.clear();
      ast.objects.addAll(encryptedObjects);

      // 5. Add /Encrypt dictionary to AST
      ast.objects[encryptObjId] = handler.createEncryptionDictionary();
      ast.objectGenerations[encryptObjId] = 0;

      // 6. Update Trailer dictionary
      ast.trailer['Encrypt'] = PdfRef(encryptObjId);
      ast.trailer['ID'] = PdfArray([
        PdfString(fileId, isHex: true),
        PdfString(fileId, isHex: true),
      ]);

      // 7. Write atomically to target path
      final writer = PdfWriter(ast);
      final outputFile = writer.writeAtomicSync(targetFilePath);
      final outputSize = outputFile.lengthSync();

      return PdfEncryptionResult.completed(
        outputPath: targetFilePath,
        encryptedSizeBytes: outputSize,
        algorithm: config.algorithm,
      );
    } catch (e) {
      return PdfEncryptionResult.failed('PDF Encryption failed: $e');
    }
  }

  /// Extracts 16-byte file ID from `/ID` in trailer, or generates a fresh ID.
  static Uint8List _resolveFileId(PdfDocumentAst ast) {
    final idArray = ast.trailer.getArray('ID');
    if (idArray != null && idArray.isNotEmpty) {
      final first = idArray[0];
      if (first is PdfString && first.bytes.isNotEmpty) {
        final idBytes = Uint8List(16);
        final copyLen = first.bytes.length.clamp(0, 16);
        idBytes.setRange(0, copyLen, first.bytes);
        return idBytes;
      }
    }
    // Generate fresh 16-byte random ID
    return PdfAes128Cbc.generateIv();
  }

  /// Recursively encrypts strings and streams within an AST object.
  static PdfObject _encryptPdfObject({
    required PdfObject obj,
    required int objId,
    required int gen,
    required PdfStandardSecurityHandler handler,
  }) {
    if (obj is PdfStream) {
      final encryptedBytes = handler.encryptData(
        objId: objId,
        gen: gen,
        plainData: obj.data,
      );

      final encryptedDict = _encryptPdfDict(
        dict: obj.dict,
        objId: objId,
        gen: gen,
        handler: handler,
      );

      return PdfStream(dict: encryptedDict, data: encryptedBytes);
    } else if (obj is PdfString) {
      final encryptedBytes = handler.encryptData(
        objId: objId,
        gen: gen,
        plainData: obj.bytes,
      );
      return PdfString(encryptedBytes, isHex: true);
    } else if (obj is PdfDict) {
      return _encryptPdfDict(
        dict: obj,
        objId: objId,
        gen: gen,
        handler: handler,
      );
    } else if (obj is PdfArray) {
      final newItems = <PdfObject>[];
      for (final item in obj.items) {
        newItems.add(_encryptPdfObject(
          obj: item,
          objId: objId,
          gen: gen,
          handler: handler,
        ));
      }
      return PdfArray(newItems);
    }

    // Primitives like PdfNumber, PdfName, PdfBoolean, PdfNull, PdfRef remain unencrypted
    return obj;
  }

  static PdfDict _encryptPdfDict({
    required PdfDict dict,
    required int objId,
    required int gen,
    required PdfStandardSecurityHandler handler,
  }) {
    final newEntries = <String, PdfObject>{};
    for (final entry in dict.entries.entries) {
      // PDF dictionary keys remain names, values are recursively processed
      newEntries[entry.key] = _encryptPdfObject(
        obj: entry.value,
        objId: objId,
        gen: gen,
        handler: handler,
      );
    }
    return PdfDict(newEntries);
  }
}
