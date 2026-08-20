import 'package:meta/meta.dart';
import 'pdf_geometry.dart';

/// Normalized RGB color representation (0.0 to 1.0 per channel) for PDF native objects.
@immutable
class PdfColor {
  final double r;
  final double g;
  final double b;

  const PdfColor(this.r, this.g, this.b);

  const PdfColor.yellow() : this(1.0, 0.92, 0.23);
  const PdfColor.green() : this(0.3, 0.85, 0.39);
  const PdfColor.blue() : this(0.25, 0.65, 0.95);
  const PdfColor.pink() : this(1.0, 0.45, 0.65);
  const PdfColor.purple() : this(0.68, 0.42, 0.88);
  const PdfColor.red() : this(0.95, 0.26, 0.21);
  const PdfColor.black() : this(0.0, 0.0, 0.0);
  const PdfColor.white() : this(1.0, 1.0, 1.0);

  /// Creates a [PdfColor] from an 8-bit hex ARGB or RGB integer (e.g. 0xFFFFEB3B).
  factory PdfColor.fromInt(int value) {
    final r = ((value >> 16) & 0xFF) / 255.0;
    final g = ((value >> 8) & 0xFF) / 255.0;
    final b = (value & 0xFF) / 255.0;
    return PdfColor(r, g, b);
  }

  /// Converts this color to a 3-element double list for PDF `/C` entries `[r, g, b]`.
  List<double> toPdfArray() => [r, g, b];

  /// Converts to 32-bit ARGB hex integer with optional [opacity] (0.0 to 1.0).
  int toArgbInt([double opacity = 1.0]) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round() & 0xFF;
    final red = (r.clamp(0.0, 1.0) * 255).round() & 0xFF;
    final green = (g.clamp(0.0, 1.0) * 255).round() & 0xFF;
    final blue = (b.clamp(0.0, 1.0) * 255).round() & 0xFF;
    return (a << 24) | (red << 16) | (green << 8) | blue;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfColor &&
          (other.r - r).abs() < 1e-3 &&
          (other.g - g).abs() < 1e-3 &&
          (other.b - b).abs() < 1e-3;

  @override
  int get hashCode => Object.hash(
      r.toStringAsFixed(2), g.toStringAsFixed(2), b.toStringAsFixed(2));

  @override
  String toString() =>
      'PdfColor(r:${r.toStringAsFixed(2)}, g:${g.toStringAsFixed(2)}, b:${b.toStringAsFixed(2)})';
}

/// Base sealed model representing an ISO 32000-1 compliant PDF native annotation.
@immutable
abstract class PdfNativeAnnotation {
  /// Unique identifier (e.g. UUID / NM entry).
  final String id;

  /// 0-based page index where this annotation resides.
  final int pageIndex;

  /// Axis-aligned bounding box in PDF user space coordinates (points, bottom-left origin).
  final PdfBoundingBox boundingBox;

  /// Standard annotation stroke or fill color.
  final PdfColor color;

  /// Opacity (`/CA`) ranging from 0.0 (transparent) to 1.0 (opaque).
  final double opacity;

  /// Textual contents (`/Contents`) associated with the annotation.
  final String contents;

  /// Author / creator name (`/T`).
  final String author;

  /// Creation date / timestamp.
  final DateTime creationDate;

  /// Last modification date / timestamp.
  final DateTime modificationDate;

  /// Annotation flags (`/F` bitmask: Print = 4, NoZoom = 8, etc.).
  final int flags;

  const PdfNativeAnnotation({
    required this.id,
    required this.pageIndex,
    required this.boundingBox,
    this.color = const PdfColor.yellow(),
    this.opacity = 1.0,
    this.contents = '',
    this.author = 'TITAN Reader',
    required this.creationDate,
    required this.modificationDate,
    this.flags = 4, // Print flag standard default
  });

  /// The standard PDF `/Subtype` name (e.g. 'Highlight', 'Underline', 'Ink', etc.).
  String get subtype;

  /// Creates a copy with modified fields.
  PdfNativeAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
  });
}

/// PDF Native Highlight Annotation (`/Subtype /Highlight`, ISO 32000-1 §12.5.6.10).
class PdfNativeHighlightAnnotation extends PdfNativeAnnotation {
  final List<PdfQuadPoint> quadPoints;

  const PdfNativeHighlightAnnotation({
    required super.id,
    required super.pageIndex,
    required super.boundingBox,
    super.color = const PdfColor.yellow(),
    super.opacity = 0.4,
    super.contents = '',
    super.author = 'TITAN Reader',
    required super.creationDate,
    required super.modificationDate,
    super.flags = 4,
    required this.quadPoints,
  });

  @override
  String get subtype => 'Highlight';

  @override
  PdfNativeHighlightAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
    List<PdfQuadPoint>? quadPoints,
  }) {
    return PdfNativeHighlightAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      contents: contents ?? this.contents,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      flags: flags ?? this.flags,
      quadPoints: quadPoints ?? this.quadPoints,
    );
  }
}

/// PDF Native Underline Annotation (`/Subtype /Underline`, ISO 32000-1 §12.5.6.10).
class PdfNativeUnderlineAnnotation extends PdfNativeAnnotation {
  final List<PdfQuadPoint> quadPoints;

  const PdfNativeUnderlineAnnotation({
    required super.id,
    required super.pageIndex,
    required super.boundingBox,
    super.color = const PdfColor.blue(),
    super.opacity = 1.0,
    super.contents = '',
    super.author = 'TITAN Reader',
    required super.creationDate,
    required super.modificationDate,
    super.flags = 4,
    required this.quadPoints,
  });

  @override
  String get subtype => 'Underline';

  @override
  PdfNativeUnderlineAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
    List<PdfQuadPoint>? quadPoints,
  }) {
    return PdfNativeUnderlineAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      contents: contents ?? this.contents,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      flags: flags ?? this.flags,
      quadPoints: quadPoints ?? this.quadPoints,
    );
  }
}

/// PDF Native StrikeOut Annotation (`/Subtype /StrikeOut`, ISO 32000-1 §12.5.6.10).
class PdfNativeStrikeOutAnnotation extends PdfNativeAnnotation {
  final List<PdfQuadPoint> quadPoints;

  const PdfNativeStrikeOutAnnotation({
    required super.id,
    required super.pageIndex,
    required super.boundingBox,
    super.color = const PdfColor.red(),
    super.opacity = 1.0,
    super.contents = '',
    super.author = 'TITAN Reader',
    required super.creationDate,
    required super.modificationDate,
    super.flags = 4,
    required this.quadPoints,
  });

  @override
  String get subtype => 'StrikeOut';

  @override
  PdfNativeStrikeOutAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
    List<PdfQuadPoint>? quadPoints,
  }) {
    return PdfNativeStrikeOutAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      contents: contents ?? this.contents,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      flags: flags ?? this.flags,
      quadPoints: quadPoints ?? this.quadPoints,
    );
  }
}

/// PDF Native Ink Annotation (`/Subtype /Ink`, ISO 32000-1 §12.5.6.13).
class PdfNativeInkAnnotation extends PdfNativeAnnotation {
  /// List of stroke paths, where each stroke is a list of [PdfPoint]s.
  final List<List<PdfPoint>> inkList;

  /// Stroke width in points.
  final double strokeWidth;

  const PdfNativeInkAnnotation({
    required super.id,
    required super.pageIndex,
    required super.boundingBox,
    super.color = const PdfColor.black(),
    super.opacity = 1.0,
    super.contents = '',
    super.author = 'TITAN Reader',
    required super.creationDate,
    required super.modificationDate,
    super.flags = 4,
    required this.inkList,
    this.strokeWidth = 2.0,
  });

  @override
  String get subtype => 'Ink';

  @override
  PdfNativeInkAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
    List<List<PdfPoint>>? inkList,
    double? strokeWidth,
  }) {
    return PdfNativeInkAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      contents: contents ?? this.contents,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      flags: flags ?? this.flags,
      inkList: inkList ?? this.inkList,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

/// PDF Native FreeText Annotation (`/Subtype /FreeText`, ISO 32000-1 §12.5.6.6).
class PdfNativeFreeTextAnnotation extends PdfNativeAnnotation {
  final String text;
  final double fontSize;
  final PdfColor fontColor;
  final PdfColor? backgroundColor;
  final PdfColor? borderColor;
  final double borderWidth;

  const PdfNativeFreeTextAnnotation({
    required super.id,
    required super.pageIndex,
    required super.boundingBox,
    super.color = const PdfColor.black(),
    super.opacity = 1.0,
    super.contents = '',
    super.author = 'TITAN Reader',
    required super.creationDate,
    required super.modificationDate,
    super.flags = 4,
    required this.text,
    this.fontSize = 12.0,
    this.fontColor = const PdfColor.black(),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  String get subtype => 'FreeText';

  @override
  PdfNativeFreeTextAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
    String? text,
    double? fontSize,
    PdfColor? fontColor,
    PdfColor? backgroundColor,
    PdfColor? borderColor,
    double? borderWidth,
  }) {
    return PdfNativeFreeTextAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      contents: contents ?? this.contents,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      flags: flags ?? this.flags,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }
}

/// PDF Native Sticky Note / Text Annotation (`/Subtype /Text`, ISO 32000-1 §12.5.6.4).
class PdfNativeTextAnnotation extends PdfNativeAnnotation {
  final String iconName; // 'Comment', 'Note', 'Help', 'Key', etc.
  final bool isOpen;

  const PdfNativeTextAnnotation({
    required super.id,
    required super.pageIndex,
    required super.boundingBox,
    super.color = const PdfColor.yellow(),
    super.opacity = 1.0,
    super.contents = '',
    super.author = 'TITAN Reader',
    required super.creationDate,
    required super.modificationDate,
    super.flags = 4,
    this.iconName = 'Comment',
    this.isOpen = false,
  });

  @override
  String get subtype => 'Text';

  @override
  PdfNativeTextAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
    String? iconName,
    bool? isOpen,
  }) {
    return PdfNativeTextAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      contents: contents ?? this.contents,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      flags: flags ?? this.flags,
      iconName: iconName ?? this.iconName,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

/// Preserved raw / unknown native annotation (Link, Stamp, Widget, Popup, etc.).
class PdfNativeRawAnnotation extends PdfNativeAnnotation {
  final String rawSubtype;
  final Map<String, dynamic> rawProperties;

  const PdfNativeRawAnnotation({
    required super.id,
    required super.pageIndex,
    required super.boundingBox,
    super.color = const PdfColor.black(),
    super.opacity = 1.0,
    super.contents = '',
    super.author = '',
    required super.creationDate,
    required super.modificationDate,
    super.flags = 4,
    required this.rawSubtype,
    this.rawProperties = const {},
  });

  @override
  String get subtype => rawSubtype;

  @override
  PdfNativeRawAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfBoundingBox? boundingBox,
    PdfColor? color,
    double? opacity,
    String? contents,
    String? author,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? flags,
    String? rawSubtype,
    Map<String, dynamic>? rawProperties,
  }) {
    return PdfNativeRawAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      contents: contents ?? this.contents,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      flags: flags ?? this.flags,
      rawSubtype: rawSubtype ?? this.rawSubtype,
      rawProperties: rawProperties ?? this.rawProperties,
    );
  }
}
