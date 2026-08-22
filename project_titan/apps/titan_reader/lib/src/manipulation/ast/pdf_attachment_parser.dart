import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/pdf_embedded_file.dart';
import '../../domain/entities/pdf_filename_sanitizer.dart';
import 'pdf_document_ast.dart';
import 'pdf_primitive.dart';

/// Standards-compliant parser for discovering and extracting embedded files in PDF documents (ISO 32000-1 §7.11 & §12.5.6.15).
class PdfAttachmentParser {
  /// Maximum stream allocation limit to prevent memory exhaustion from zip bombs or malformed streams (100 MB).
  static const int maxDecompressedSizeBytes = 100 * 1024 * 1024;

  final PdfDocumentAst ast;

  const PdfAttachmentParser(this.ast);

  /// Discovers all embedded files declared in the document.
  List<PdfEmbeddedFile> parseAllAttachments() {
    final results = <PdfEmbeddedFile>[];
    final seenStreamObjectNumbers = <int>{};

    // 1. Discover Document-Level Embedded Files from Catalog /Names /EmbeddedFiles
    _discoverCatalogNamesEmbeddedFiles(results, seenStreamObjectNumbers);

    // 2. Discover Document-Level Associated Files from Catalog /AF (PDF/A-3 & PDF 2.0)
    _discoverCatalogAssociatedFiles(results, seenStreamObjectNumbers);

    // 3. Discover Document-Level direct /EmbeddedFiles (legacy/non-standard fallback)
    _discoverCatalogDirectEmbeddedFiles(results, seenStreamObjectNumbers);

    // 4. Discover Page-Level File Attachment Annotations (/Subtype /FileAttachment)
    _discoverPageAnnotationAttachments(results, seenStreamObjectNumbers);

    return results;
  }

  /// Extracts and decompresses the raw bytes of an embedded file stream.
  Uint8List extractAttachmentBytes(PdfEmbeddedFile attachment) {
    final streamObj = ast.objects[attachment.streamObjectNumber];
    if (streamObj is! PdfStream) {
      throw StateError(
          'Indirect object ${attachment.streamObjectNumber} is not a valid PDF Stream.');
    }

    final rawData = streamObj.data;
    if (rawData.isEmpty) return Uint8List(0);

    final filter = streamObj.dict['Filter'];
    final isFlate = _isFlateDecodeFilter(filter);

    if (!isFlate) {
      // Uncompressed stream
      return rawData;
    }

    try {
      // Decompress FlateDecode (ZLib / Deflate)
      final decompressed = zlib.decode(rawData);
      if (decompressed.length > maxDecompressedSizeBytes) {
        throw StateError(
            'Decompressed stream size exceeds safety threshold (${decompressed.length} bytes > $maxDecompressedSizeBytes bytes).');
      }
      return Uint8List.fromList(decompressed);
    } catch (_) {
      // If zlib header parsing fails, attempt raw deflate decoding
      try {
        final rawDeflate = ZLibDecoder(raw: true).convert(rawData);
        return Uint8List.fromList(rawDeflate);
      } catch (_) {
        // Fallback to raw stream data if decompression fails
        return rawData;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Discovery Helpers
  // ---------------------------------------------------------------------------

  void _discoverCatalogNamesEmbeddedFiles(
    List<PdfEmbeddedFile> results,
    Set<int> seenStreamObjects,
  ) {
    final namesObj = _resolveObject(ast.catalog['Names']);
    if (namesObj is! PdfDict) return;

    final embeddedFilesObj = _resolveObject(namesObj['EmbeddedFiles']);
    if (embeddedFilesObj is! PdfDict) return;

    _traverseNameTree(
      embeddedFilesObj,
      results,
      seenStreamObjects,
      PdfAttachmentSourceLocation.documentLevel,
      null,
    );
  }

  void _discoverCatalogAssociatedFiles(
    List<PdfEmbeddedFile> results,
    Set<int> seenStreamObjects,
  ) {
    final afObj = _resolveObject(ast.catalog['AF']);
    if (afObj is! PdfArray) return;

    for (final item in afObj.items) {
      final fileSpecDict = _resolveObject(item);
      if (fileSpecDict is PdfDict) {
        _processFileSpec(
          fileSpecDict: fileSpecDict,
          results: results,
          seenStreamObjects: seenStreamObjects,
          sourceLocation: PdfAttachmentSourceLocation.documentLevel,
          pageNumber: null,
        );
      }
    }
  }

  void _discoverCatalogDirectEmbeddedFiles(
    List<PdfEmbeddedFile> results,
    Set<int> seenStreamObjects,
  ) {
    final efObj = _resolveObject(ast.catalog['EmbeddedFiles']);
    if (efObj is! PdfDict) return;

    _traverseNameTree(
      efObj,
      results,
      seenStreamObjects,
      PdfAttachmentSourceLocation.documentLevel,
      null,
    );
  }

  void _discoverPageAnnotationAttachments(
    List<PdfEmbeddedFile> results,
    Set<int> seenStreamObjects,
  ) {
    for (var pageIdx = 0; pageIdx < ast.pageCount; pageIdx++) {
      final pageNum = pageIdx + 1;
      final pageDict = ast.getPageDict(pageIdx);
      final annotsObj = _resolveObject(pageDict['Annots']);
      if (annotsObj is! PdfArray) continue;

      for (final annotRef in annotsObj.items) {
        final annotDict = _resolveObject(annotRef);
        if (annotDict is! PdfDict) continue;

        final subtype = annotDict.getName('Subtype');
        if (subtype == 'FileAttachment') {
          final fsObj = _resolveObject(annotDict['FS']);
          if (fsObj is PdfDict) {
            _processFileSpec(
              fileSpecDict: fsObj,
              results: results,
              seenStreamObjects: seenStreamObjects,
              sourceLocation: PdfAttachmentSourceLocation.annotation,
              pageNumber: pageNum,
            );
          }
        }
      }
    }
  }

  void _traverseNameTree(
    PdfDict node,
    List<PdfEmbeddedFile> results,
    Set<int> seenStreamObjects,
    PdfAttachmentSourceLocation sourceLocation,
    int? pageNumber,
  ) {
    // 1. Direct /Names array: [(name1), Ref1, (name2), Ref2, ...]
    final namesArray = _resolveObject(node['Names']);
    if (namesArray is PdfArray) {
      for (var i = 0; i + 1 < namesArray.length; i += 2) {
        final fileSpecDict = _resolveObject(namesArray[i + 1]);
        if (fileSpecDict is PdfDict) {
          _processFileSpec(
            fileSpecDict: fileSpecDict,
            results: results,
            seenStreamObjects: seenStreamObjects,
            sourceLocation: sourceLocation,
            pageNumber: pageNumber,
          );
        }
      }
    }

    // 2. Hierarchical /Kids array: [KidRef1, KidRef2, ...]
    final kidsArray = _resolveObject(node['Kids']);
    if (kidsArray is PdfArray) {
      for (final kid in kidsArray.items) {
        final kidNode = _resolveObject(kid);
        if (kidNode is PdfDict) {
          _traverseNameTree(
            kidNode,
            results,
            seenStreamObjects,
            sourceLocation,
            pageNumber,
          );
        }
      }
    }
  }

  void _processFileSpec({
    required PdfDict fileSpecDict,
    required List<PdfEmbeddedFile> results,
    required Set<int> seenStreamObjects,
    required PdfAttachmentSourceLocation sourceLocation,
    required int? pageNumber,
  }) {
    // Extract filename strings (/UF for Unicode, /F for ASCII, /DOS, /Mac, /Unix)
    final ufStr = _resolveObject(fileSpecDict['UF']);
    final fStr = _resolveObject(fileSpecDict['F']);
    final descStr = _resolveObject(fileSpecDict['Desc']);
    final afRel = fileSpecDict.getName('AFRelationship');

    String? unicodeFilename;
    if (ufStr is PdfString) {
      unicodeFilename = ufStr.asString();
    }

    String? originalFilename;
    if (fStr is PdfString) {
      originalFilename = fStr.asString();
    }

    String? description;
    if (descStr is PdfString) {
      description = descStr.asString();
    }

    // Extract Embedded Files dictionary /EF
    final efDict = _resolveObject(fileSpecDict['EF']);
    if (efDict is! PdfDict) return;

    // Resolve stream reference (prefer /UF stream, fallback to /F, /DOS, /Mac, /Unix)
    PdfRef? streamRef;
    final efUf = efDict['UF'];
    final efF = efDict['F'];
    if (efUf is PdfRef) {
      streamRef = efUf;
    } else if (efF is PdfRef) {
      streamRef = efF;
    } else {
      for (final val in efDict.entries.values) {
        if (val is PdfRef) {
          streamRef = val;
          break;
        }
      }
    }

    if (streamRef == null) return;

    final streamObjNum = streamRef.objectNumber;
    if (seenStreamObjects.contains(streamObjNum)) return;
    seenStreamObjects.add(streamObjNum);

    final streamObj = ast.objects[streamObjNum];
    if (streamObj is! PdfStream) return;

    // Extract /Subtype and /Params from stream dictionary
    final subtype = streamObj.dict.getName('Subtype');
    final paramsDict = _resolveObject(streamObj.dict['Params']);

    int? declaredSize;
    String? creationDate;
    String? modDate;

    if (paramsDict is PdfDict) {
      declaredSize = paramsDict.getInt('Size');
      final cDate = _resolveObject(paramsDict['CreationDate']);
      if (cDate is PdfString) creationDate = cDate.asString();
      final mDate = _resolveObject(paramsDict['ModDate']);
      if (mDate is PdfString) modDate = mDate.asString();
    }

    // Best-effort filename resolution
    final preferredName =
        (unicodeFilename != null && unicodeFilename.isNotEmpty)
            ? unicodeFilename
            : (originalFilename != null && originalFilename.isNotEmpty)
                ? originalFilename
                : 'attachment_$streamObjNum.bin';

    final safeFilename = PdfFilenameSanitizer.sanitize(preferredName);

    final attachment = PdfEmbeddedFile(
      id: 'emb_${streamObjNum}_${streamRef.generationNumber}',
      filename: safeFilename,
      originalFilename: originalFilename,
      unicodeFilename: unicodeFilename,
      description: description,
      mimeType: subtype != null ? _normalizeMimeType(subtype) : null,
      declaredSize: declaredSize,
      actualSize: streamObj.data.length,
      creationDate: creationDate,
      modificationDate: modDate,
      relationship: afRel,
      sourceLocation: sourceLocation,
      pageNumber: pageNumber,
      streamObjectNumber: streamObjNum,
      streamGeneration: streamRef.generationNumber,
    );

    results.add(attachment);
  }

  PdfObject? _resolveObject(PdfObject? obj) {
    if (obj is PdfRef) {
      return ast.objects[obj.objectNumber];
    }
    return obj;
  }

  static bool _isFlateDecodeFilter(PdfObject? filter) {
    if (filter is PdfName) {
      return filter.name == 'FlateDecode' || filter.name == 'Fl';
    }
    if (filter is PdfArray) {
      for (final item in filter.items) {
        if (item is PdfName &&
            (item.name == 'FlateDecode' || item.name == 'Fl')) {
          return true;
        }
      }
    }
    return false;
  }

  static String _normalizeMimeType(String name) {
    // Unescape PDF name encoding e.g. application#2Fpdf -> application/pdf
    return name.replaceAll('#2F', '/').replaceAll('#2f', '/');
  }
}
