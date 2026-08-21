import 'dart:convert';
import 'dart:io';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/normalized_page_rect.dart';
import '../domain/entities/pdf_geometry.dart';
import '../domain/entities/pdf_native_annotation.dart';
import '../domain/entities/pdf_visual_signature.dart';
import '../manipulation/ast/pdf_annotation_builder.dart';
import '../manipulation/ast/pdf_parser.dart';
import '../manipulation/ast/pdf_primitive.dart';
import '../manipulation/ast/pdf_writer.dart';

/// Storage repository and service for managing reusable local visual signatures
/// and stamping them into PDF documents.
class SignatureService {
  final StorageService _storage;
  static const String _namespace = 'titan.reader.signatures';
  static const StorageKey _storageKey =
      StorageKey('library', namespace: _namespace);

  final List<PdfVisualSignature> _cachedSignatures = [];
  bool _loaded = false;

  SignatureService(this._storage);

  /// Synchronous snapshot of all loaded signatures.
  List<PdfVisualSignature> get signatures =>
      List.unmodifiable(_cachedSignatures);

  /// Generates a unique signature ID.
  String nextId() => 'sig_${DateTime.now().microsecondsSinceEpoch}';

  /// Ensures saved signatures are loaded from local storage into memory.
  Future<List<PdfVisualSignature>> ensureLoaded() async {
    if (_loaded) return signatures;
    final raw = await _storage.read<String>(_storageKey);
    _cachedSignatures.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          _cachedSignatures
              .add(PdfVisualSignature.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {
        // Tolerant of corrupted/empty cache
      }
    }
    _loaded = true;
    return signatures;
  }

  /// Retrieves a saved signature by its unique [id].
  PdfVisualSignature? getSignatureById(String id) {
    try {
      return _cachedSignatures.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Saves or updates a signature in local storage.
  Future<void> saveSignature(PdfVisualSignature signature) async {
    await ensureLoaded();
    final index = _cachedSignatures.indexWhere((s) => s.id == signature.id);
    if (index >= 0) {
      _cachedSignatures[index] = signature.copyWith(updatedAt: DateTime.now());
    } else {
      _cachedSignatures.add(signature);
    }
    await _persist();
  }

  /// Deletes a signature from local storage by [id].
  Future<bool> deleteSignature(String id) async {
    await ensureLoaded();
    final initialLength = _cachedSignatures.length;
    _cachedSignatures.removeWhere((s) => s.id == id);
    if (_cachedSignatures.length != initialLength) {
      await _persist();
      return true;
    }
    return false;
  }

  Future<void> _persist() async {
    final list = _cachedSignatures.map((s) => s.toJson()).toList();
    await _storage.write<String>(_storageKey, jsonEncode(list));
  }

  /// Stamps a [signature] onto [pageIndex] (0-based) of the PDF at [sourceFilePath].
  ///
  /// The [rect] is expressed in canonical normalized coordinates (0.0 to 1.0, top-left origin).
  /// If [outputPath] is provided, writes to [outputPath]; otherwise updates [sourceFilePath]
  /// atomically using a temporary file.
  Future<String> stampSignatureOnPdf({
    required String sourceFilePath,
    required int pageIndex,
    required NormalizedPageRect rect,
    required PdfVisualSignature signature,
    String? outputPath,
  }) async {
    final file = File(sourceFilePath);
    if (!await file.exists()) {
      throw FileSystemException(
          'Source PDF file does not exist', sourceFilePath);
    }

    final bytes = await file.readAsBytes();
    final ast = PdfParser(bytes).parse();

    if (pageIndex < 0 || pageIndex >= ast.pageCount) {
      throw RangeError.range(pageIndex, 0, ast.pageCount - 1, 'pageIndex');
    }

    final pageDict = ast.getPageDict(pageIndex);
    final mediaBox = pageDict.getArray('MediaBox');
    double pageWidth = 612.0;
    double pageHeight = 792.0;
    if (mediaBox != null && mediaBox.length >= 4) {
      pageWidth = (mediaBox[2] as PdfNumber).value.toDouble() -
          (mediaBox[0] as PdfNumber).value.toDouble();
      pageHeight = (mediaBox[3] as PdfNumber).value.toDouble() -
          (mediaBox[1] as PdfNumber).value.toDouble();
    }

    // Convert normalized top-left coordinates to PDF user points (bottom-left origin)
    final pdfLeft = rect.left * pageWidth;
    final pdfRight = rect.right * pageWidth;
    final pdfTop = pageHeight - (rect.top * pageHeight);
    final pdfBottom = pageHeight - (rect.bottom * pageHeight);
    final bbox = PdfBoundingBox(
      left: pdfLeft,
      bottom: pdfBottom < pdfTop ? pdfBottom : pdfTop,
      right: pdfRight,
      top: pdfTop > pdfBottom ? pdfTop : pdfBottom,
    );

    final now = DateTime.now();
    final annotId = 'sig_${now.microsecondsSinceEpoch}';
    final annotColor = PdfColor.fromInt(signature.colorArgb);

    PdfNativeAnnotation nativeAnnot;
    switch (signature.type) {
      case PdfSignatureType.drawn:
        final scaledStrokes = <List<PdfPoint>>[];
        for (final stroke in signature.strokes) {
          final points = <PdfPoint>[];
          for (final p in stroke) {
            final px = bbox.left + (p.x * bbox.width);
            // Invert Y so 0.0 is top in signature pad, matching PDF user coordinates
            final py = bbox.top - (p.y * bbox.height);
            points.add(PdfPoint(px, py));
          }
          scaledStrokes.add(points);
        }
        nativeAnnot = PdfNativeInkAnnotation(
          id: annotId,
          pageIndex: pageIndex,
          boundingBox: bbox,
          color: annotColor,
          contents: 'Signature: ${signature.name}',
          author: 'TITAN Signature',
          creationDate: now,
          modificationDate: now,
          inkList: scaledStrokes,
          strokeWidth: 2.0,
        );
      case PdfSignatureType.typed:
        nativeAnnot = PdfNativeFreeTextAnnotation(
          id: annotId,
          pageIndex: pageIndex,
          boundingBox: bbox,
          color: annotColor,
          fontColor: annotColor,
          contents: 'Signature: ${signature.name}',
          author: 'TITAN Signature',
          creationDate: now,
          modificationDate: now,
          text: signature.typedText,
          fontSize: (bbox.height * 0.45).clamp(10.0, 48.0),
        );
      case PdfSignatureType.image:
        nativeAnnot = PdfNativeRawAnnotation(
          id: annotId,
          pageIndex: pageIndex,
          boundingBox: bbox,
          color: annotColor,
          contents: 'Signature: ${signature.name}',
          author: 'TITAN Signature',
          creationDate: now,
          modificationDate: now,
          rawSubtype: 'Stamp',
        );
    }

    // Allocate object number for the new annotation dictionary
    final annotObjNum = ast.nextAvailableObjectNumber();
    final annotDict = PdfAnnotationBuilder.buildAnnotationDict(nativeAnnot);
    ast.objects[annotObjNum] = annotDict;
    ast.objectGenerations[annotObjNum] = 0;

    // Attach to page /Annots array
    var annotsArray = pageDict.getArray('Annots');
    if (annotsArray == null) {
      final newAnnots = PdfArray([PdfRef(annotObjNum)]);
      pageDict['Annots'] = newAnnots;
    } else {
      final mutable = List<PdfObject>.from(annotsArray.items);
      mutable.add(PdfRef(annotObjNum));
      pageDict['Annots'] = PdfArray(mutable);
    }

    final outBytes = PdfWriter(ast).writeBytes();
    final targetPath = outputPath ?? sourceFilePath;
    final tempFile = File('$targetPath.tmp_${now.microsecondsSinceEpoch}');
    await tempFile.writeAsBytes(outBytes, flush: true);
    await tempFile.rename(targetPath);

    return targetPath;
  }
}
