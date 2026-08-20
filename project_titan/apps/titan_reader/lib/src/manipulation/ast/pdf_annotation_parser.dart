import '../../domain/entities/pdf_geometry.dart';
import '../../domain/entities/pdf_native_annotation.dart';
import 'pdf_document_ast.dart';
import 'pdf_primitive.dart';

/// Parses ISO 32000-1 `/Annot` dictionaries from [PdfDocumentAst] page objects.
class PdfAnnotationParser {
  /// Extracts all native annotations present on page at [pageIndex] (0-based).
  static List<PdfNativeAnnotation> parsePageAnnotations(
    PdfDocumentAst ast,
    int pageIndex,
  ) {
    if (pageIndex < 0 || pageIndex >= ast.pageCount) return const [];

    final pageDict = ast.getPageDict(pageIndex);
    final annotsArray = pageDict.getArray('Annots');
    if (annotsArray == null || annotsArray.isEmpty) return const [];

    final result = <PdfNativeAnnotation>[];

    for (var i = 0; i < annotsArray.length; i++) {
      final item = annotsArray[i];
      PdfDict? annotDict;

      if (item is PdfRef) {
        final obj = ast.objects[item.objectNumber];
        if (obj is PdfDict) {
          annotDict = obj;
        }
      } else if (item is PdfDict) {
        annotDict = item;
      }

      if (annotDict != null) {
        final parsed = parseAnnotationDict(annotDict,
            pageIndex: pageIndex, fallbackIndex: i);
        if (parsed != null) {
          result.add(parsed);
        }
      }
    }

    return result;
  }

  /// Parses a single [PdfDict] into a structured [PdfNativeAnnotation].
  static PdfNativeAnnotation? parseAnnotationDict(
    PdfDict dict, {
    required int pageIndex,
    int fallbackIndex = 0,
  }) {
    final subtype = dict.getName('Subtype');
    if (subtype == null) return null;

    final id =
        dict.getString('NM')?.asString() ?? 'annot_${pageIndex}_$fallbackIndex';
    final contents = dict.getString('Contents')?.asString() ?? '';
    final author = dict.getString('T')?.asString() ?? '';
    final flags = dict.getInt('F') ?? 4;
    final opacity = dict.getDouble('CA') ?? 1.0;

    // Bounding Box (/Rect)
    final rectArray = dict.getArray('Rect');
    PdfBoundingBox box;
    if (rectArray != null && rectArray.length >= 4) {
      box = PdfBoundingBox(
        left: _asDouble(rectArray[0]),
        bottom: _asDouble(rectArray[1]),
        right: _asDouble(rectArray[2]),
        top: _asDouble(rectArray[3]),
      ).normalized();
    } else {
      box = const PdfBoundingBox(left: 0, bottom: 0, right: 100, top: 100);
    }

    // Color (/C)
    final cArray = dict.getArray('C');
    PdfColor color;
    if (cArray != null && cArray.length >= 3) {
      color = PdfColor(
        _asDouble(cArray[0]),
        _asDouble(cArray[1]),
        _asDouble(cArray[2]),
      );
    } else {
      color = subtype == 'Highlight'
          ? const PdfColor.yellow()
          : subtype == 'Underline'
              ? const PdfColor.blue()
              : subtype == 'StrikeOut'
                  ? const PdfColor.red()
                  : const PdfColor.black();
    }

    // Dates
    final mDate =
        _parsePdfDate(dict.getString('M')?.asString()) ?? DateTime.now();
    final cDate =
        _parsePdfDate(dict.getString('CreationDate')?.asString()) ?? mDate;

    // Type Dispatch
    switch (subtype) {
      case 'Highlight':
        final quads = _parseQuadPoints(dict.getArray('QuadPoints'), box);
        return PdfNativeHighlightAnnotation(
          id: id,
          pageIndex: pageIndex,
          boundingBox: box,
          color: color,
          opacity: opacity < 1.0 ? opacity : 0.4,
          contents: contents,
          author: author,
          creationDate: cDate,
          modificationDate: mDate,
          flags: flags,
          quadPoints: quads,
        );

      case 'Underline':
        final quads = _parseQuadPoints(dict.getArray('QuadPoints'), box);
        return PdfNativeUnderlineAnnotation(
          id: id,
          pageIndex: pageIndex,
          boundingBox: box,
          color: color,
          opacity: opacity,
          contents: contents,
          author: author,
          creationDate: cDate,
          modificationDate: mDate,
          flags: flags,
          quadPoints: quads,
        );

      case 'StrikeOut':
        final quads = _parseQuadPoints(dict.getArray('QuadPoints'), box);
        return PdfNativeStrikeOutAnnotation(
          id: id,
          pageIndex: pageIndex,
          boundingBox: box,
          color: color,
          opacity: opacity,
          contents: contents,
          author: author,
          creationDate: cDate,
          modificationDate: mDate,
          flags: flags,
          quadPoints: quads,
        );

      case 'Ink':
        final inkList = _parseInkList(dict.getArray('InkList'));
        final bsDict = dict.getDict('BS');
        final strokeWidth = bsDict?.getDouble('W') ?? 2.0;
        return PdfNativeInkAnnotation(
          id: id,
          pageIndex: pageIndex,
          boundingBox: box,
          color: color,
          opacity: opacity,
          contents: contents,
          author: author,
          creationDate: cDate,
          modificationDate: mDate,
          flags: flags,
          inkList: inkList,
          strokeWidth: strokeWidth,
        );

      case 'FreeText':
        final text = contents;
        final bsDict = dict.getDict('BS');
        final borderWidth = bsDict?.getDouble('W') ?? 1.0;
        return PdfNativeFreeTextAnnotation(
          id: id,
          pageIndex: pageIndex,
          boundingBox: box,
          color: color,
          opacity: opacity,
          contents: contents,
          author: author,
          creationDate: cDate,
          modificationDate: mDate,
          flags: flags,
          text: text,
          fontColor: color,
          borderWidth: borderWidth,
        );

      case 'Text':
        final iconName = dict.getName('Name') ?? 'Comment';
        final isOpen =
            dict['Open'] is PdfBoolean && (dict['Open'] as PdfBoolean).value;
        return PdfNativeTextAnnotation(
          id: id,
          pageIndex: pageIndex,
          boundingBox: box,
          color: color,
          opacity: opacity,
          contents: contents,
          author: author,
          creationDate: cDate,
          modificationDate: mDate,
          flags: flags,
          iconName: iconName,
          isOpen: isOpen,
        );

      default:
        // Preserved Raw Unknown / Custom Annotation
        return PdfNativeRawAnnotation(
          id: id,
          pageIndex: pageIndex,
          boundingBox: box,
          color: color,
          opacity: opacity,
          contents: contents,
          author: author,
          creationDate: cDate,
          modificationDate: mDate,
          flags: flags,
          rawSubtype: subtype,
        );
    }
  }

  static List<PdfQuadPoint> _parseQuadPoints(
      PdfArray? array, PdfBoundingBox fallbackBox) {
    if (array == null || array.length < 8) {
      return [PdfQuadPoint.fromBox(fallbackBox)];
    }

    final quads = <PdfQuadPoint>[];
    for (var i = 0; i + 7 < array.length; i += 8) {
      quads.add(PdfQuadPoint(
        x1: _asDouble(array[i]),
        y1: _asDouble(array[i + 1]),
        x2: _asDouble(array[i + 2]),
        y2: _asDouble(array[i + 3]),
        x3: _asDouble(array[i + 4]),
        y3: _asDouble(array[i + 5]),
        x4: _asDouble(array[i + 6]),
        y4: _asDouble(array[i + 7]),
      ));
    }
    return quads.isNotEmpty ? quads : [PdfQuadPoint.fromBox(fallbackBox)];
  }

  static List<List<PdfPoint>> _parseInkList(PdfArray? array) {
    if (array == null) return const [];
    final result = <List<PdfPoint>>[];

    for (var i = 0; i < array.length; i++) {
      final strokeItem = array[i];
      if (strokeItem is PdfArray) {
        final strokePoints = <PdfPoint>[];
        for (var j = 0; j + 1 < strokeItem.length; j += 2) {
          strokePoints.add(PdfPoint(
            _asDouble(strokeItem[j]),
            _asDouble(strokeItem[j + 1]),
          ));
        }
        if (strokePoints.isNotEmpty) {
          result.add(strokePoints);
        }
      }
    }
    return result;
  }

  static double _asDouble(PdfObject? obj) {
    if (obj is PdfNumber) return obj.asDouble;
    return 0.0;
  }

  static DateTime? _parsePdfDate(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      // PDF Date format: D:YYYYMMDDHHmmSS...
      final clean = str.startsWith('D:') ? str.substring(2) : str;
      if (clean.length < 8) return null;

      final y = int.tryParse(clean.substring(0, 4)) ?? 2026;
      final m = int.tryParse(clean.substring(4, 6)) ?? 1;
      final d = int.tryParse(clean.substring(6, 8)) ?? 1;
      var h = 0, min = 0, s = 0;
      if (clean.length >= 10) h = int.tryParse(clean.substring(8, 10)) ?? 0;
      if (clean.length >= 12) min = int.tryParse(clean.substring(10, 12)) ?? 0;
      if (clean.length >= 14) s = int.tryParse(clean.substring(12, 14)) ?? 0;

      return DateTime.utc(y, m, d, h, min, s);
    } catch (_) {
      return null;
    }
  }
}
