import 'dart:convert';
import 'dart:typed_data';
import '../../domain/entities/pdf_geometry.dart';
import '../../domain/entities/pdf_native_annotation.dart';
import 'pdf_primitive.dart';

/// Builds ISO 32000-1 compliant PDF annotation dictionaries and portable Appearance Streams.
class PdfAnnotationBuilder {
  /// Builds the complete [PdfDict] for a given [PdfNativeAnnotation].
  ///
  /// If [pageRef] is provided, sets the `/P` back-reference to the parent page object.
  /// If [appearanceStreamRef] is provided, attaches it as the normal appearance `/AP << /N ref >>`.
  static PdfDict buildAnnotationDict(
    PdfNativeAnnotation annotation, {
    PdfRef? pageRef,
    PdfRef? appearanceStreamRef,
  }) {
    final dict = PdfDict({
      'Type': const PdfName('Annot'),
      'Subtype': PdfName(annotation.subtype),
      'Rect': PdfArray(
        annotation.boundingBox.toPdfRect().map((v) => PdfNumber(v)).toList(),
      ),
      'NM': PdfString.fromString(annotation.id),
      'F': PdfNumber(annotation.flags),
      'M': PdfString.fromString(_formatPdfDate(annotation.modificationDate)),
      'CreationDate':
          PdfString.fromString(_formatPdfDate(annotation.creationDate)),
    });

    if (pageRef != null) {
      dict['P'] = pageRef;
    }

    final contentsText = (annotation is PdfNativeFreeTextAnnotation &&
            annotation.contents.isEmpty)
        ? annotation.text
        : annotation.contents;
    if (contentsText.isNotEmpty) {
      dict['Contents'] = PdfString.fromString(contentsText);
    }

    if (annotation.author.isNotEmpty) {
      dict['T'] = PdfString.fromString(annotation.author);
    }

    // Color (/C) and Opacity (/CA)
    dict['C'] = PdfArray(
      annotation.color.toPdfArray().map((v) => PdfNumber(v)).toList(),
    );
    if (annotation.opacity < 1.0) {
      dict['CA'] = PdfNumber(annotation.opacity);
    }

    // Subtype-specific entries
    if (annotation is PdfNativeHighlightAnnotation) {
      _populateQuadPoints(dict, annotation.quadPoints);
    } else if (annotation is PdfNativeUnderlineAnnotation) {
      _populateQuadPoints(dict, annotation.quadPoints);
    } else if (annotation is PdfNativeStrikeOutAnnotation) {
      _populateQuadPoints(dict, annotation.quadPoints);
    } else if (annotation is PdfNativeInkAnnotation) {
      _populateInkList(dict, annotation.inkList);
      dict['BS'] = PdfDict({'W': PdfNumber(annotation.strokeWidth)});
    } else if (annotation is PdfNativeFreeTextAnnotation) {
      dict['DA'] = PdfString.fromString(
        '/${annotation.fontSize.toInt()} Tf ${annotation.fontColor.r} ${annotation.fontColor.g} ${annotation.fontColor.b} rg',
      );
      if (annotation.borderColor != null) {
        dict['BS'] = PdfDict({'W': PdfNumber(annotation.borderWidth)});
      }
    } else if (annotation is PdfNativeTextAnnotation) {
      dict['Name'] = PdfName(annotation.iconName);
      if (annotation.isOpen) {
        dict['Open'] = const PdfBoolean(true);
      }
    }

    // Attach Appearance Stream if available
    if (appearanceStreamRef != null) {
      dict['AP'] = PdfDict({'N': appearanceStreamRef});
    }

    return dict;
  }

  /// Builds a self-contained Form XObject appearance stream for an annotation.
  static PdfStream buildAppearanceStream(
    PdfNativeAnnotation annotation,
    int extGStateObjNum,
  ) {
    final box = annotation.boundingBox.normalized();
    final width = box.width > 0 ? box.width : 1.0;
    final height = box.height > 0 ? box.height : 1.0;

    final streamDict = PdfDict({
      'Type': const PdfName('XObject'),
      'Subtype': const PdfName('Form'),
      'FormType': const PdfNumber(1),
      'BBox': PdfArray([
        const PdfNumber(0),
        const PdfNumber(0),
        PdfNumber(width),
        PdfNumber(height),
      ]),
      'Resources': PdfDict({
        'ExtGState': PdfDict({
          'GS1': PdfRef(extGStateObjNum),
        }),
      }),
    });

    final sb = StringBuffer();
    sb.writeln('/GS1 gs'); // Apply opacity and blend mode

    final r = annotation.color.r.toStringAsFixed(3);
    final g = annotation.color.g.toStringAsFixed(3);
    final b = annotation.color.b.toStringAsFixed(3);

    if (annotation is PdfNativeHighlightAnnotation) {
      // Fill rectangle with highlight color
      sb.writeln('$r $g $b rg');
      sb.writeln(
          '0 0 ${width.toStringAsFixed(2)} ${height.toStringAsFixed(2)} re f');
    } else if (annotation is PdfNativeUnderlineAnnotation) {
      // Draw underline near the bottom
      final y = (height * 0.15).clamp(1.0, height);
      sb.writeln('$r $g $b RG');
      sb.writeln('1.5 w');
      sb.writeln(
          '0 ${y.toStringAsFixed(2)} m ${width.toStringAsFixed(2)} ${y.toStringAsFixed(2)} l S');
    } else if (annotation is PdfNativeStrikeOutAnnotation) {
      // Draw line through the middle
      final y = height * 0.5;
      sb.writeln('$r $g $b RG');
      sb.writeln('1.5 w');
      sb.writeln(
          '0 ${y.toStringAsFixed(2)} m ${width.toStringAsFixed(2)} ${y.toStringAsFixed(2)} l S');
    } else if (annotation is PdfNativeInkAnnotation) {
      sb.writeln('$r $g $b RG');
      sb.writeln('${annotation.strokeWidth.toStringAsFixed(1)} w');
      sb.writeln('1 J 1 j'); // Round cap and join

      for (final stroke in annotation.inkList) {
        if (stroke.isEmpty) continue;
        final firstX = (stroke.first.x - box.left).clamp(0.0, width);
        final firstY = (stroke.first.y - box.bottom).clamp(0.0, height);
        sb.writeln(
            '${firstX.toStringAsFixed(2)} ${firstY.toStringAsFixed(2)} m');

        for (var i = 1; i < stroke.length; i++) {
          final ptX = (stroke[i].x - box.left).clamp(0.0, width);
          final ptY = (stroke[i].y - box.bottom).clamp(0.0, height);
          sb.writeln('${ptX.toStringAsFixed(2)} ${ptY.toStringAsFixed(2)} l');
        }
        sb.writeln('S');
      }
    } else if (annotation is PdfNativeFreeTextAnnotation) {
      if (annotation.backgroundColor != null) {
        final bg = annotation.backgroundColor!;
        sb.writeln('${bg.r} ${bg.g} ${bg.b} rg');
        sb.writeln(
            '0 0 ${width.toStringAsFixed(2)} ${height.toStringAsFixed(2)} re f');
      }
      if (annotation.borderColor != null) {
        final bc = annotation.borderColor!;
        sb.writeln('${bc.r} ${bc.g} ${bc.b} RG');
        sb.writeln('${annotation.borderWidth.toStringAsFixed(1)} w');
        sb.writeln(
            '0 0 ${width.toStringAsFixed(2)} ${height.toStringAsFixed(2)} re S');
      }
      if (annotation.text.isNotEmpty) {
        final fc = annotation.fontColor;
        sb.writeln('BT');
        sb.writeln('${fc.r} ${fc.g} ${fc.b} rg');
        sb.writeln('4 4 Td');
        sb.writeln('(${_escapePdfString(annotation.text)}) Tj');
        sb.writeln('ET');
      }
    } else {
      // Default fallback appearance box
      sb.writeln('$r $g $b rg');
      sb.writeln(
          '0 0 ${width.toStringAsFixed(2)} ${height.toStringAsFixed(2)} re f');
    }

    final data = Uint8List.fromList(utf8.encode(sb.toString()));
    return PdfStream(dict: streamDict, data: data);
  }

  /// Builds an `/ExtGState` dictionary configured with [opacity] and Multiply blend mode.
  static PdfDict buildExtGStateDict(double opacity) {
    return PdfDict({
      'Type': const PdfName('ExtGState'),
      'CA': PdfNumber(opacity),
      'ca': PdfNumber(opacity),
      'BM': const PdfName('Multiply'),
    });
  }

  static void _populateQuadPoints(PdfDict dict, List<PdfQuadPoint> quadPoints) {
    final nums = <PdfObject>[];
    for (final q in quadPoints) {
      for (final val in q.toList()) {
        nums.add(PdfNumber(val));
      }
    }
    dict['QuadPoints'] = PdfArray(nums);
  }

  static void _populateInkList(PdfDict dict, List<List<PdfPoint>> inkList) {
    final listArray = PdfArray();
    for (final stroke in inkList) {
      final strokeArray = PdfArray();
      for (final pt in stroke) {
        strokeArray.add(PdfNumber(pt.x));
        strokeArray.add(PdfNumber(pt.y));
      }
      listArray.add(strokeArray);
    }
    dict['InkList'] = listArray;
  }

  static String _formatPdfDate(DateTime date) {
    final utc = date.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return "D:$y$m$d$h$min$s+00'00'";
  }

  static String _escapePdfString(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('\r', '\\r')
        .replaceAll('\n', '\\n');
  }
}
