import 'package:meta/meta.dart';

import 'normalized_page_rect.dart';

/// Visual style of a text markup annotation managed by TITAN Reader.
///
/// These are Reader-managed annotations rendered as page overlays; they are
/// not embedded into the PDF file (the current PDF engine cannot create
/// PDF-native annotations).
enum ReaderAnnotationType {
  highlight,
  underline,
  strikethrough;

  String get wireName => name;

  static ReaderAnnotationType fromWire(Object? wire) {
    if (wire is String) {
      for (final type in values) {
        if (type.name == wire) return type;
      }
    }
    return ReaderAnnotationType.highlight;
  }
}

/// Highlight color palette offered by the Reader.
///
/// Persisted by wire name so palette tweaks never break stored data. The
/// concrete ARGB values are supplied by the UI layer ([argb] keeps the domain
/// free of framework color types).
enum ReaderAnnotationColor {
  yellow(0xFFE8C54A),
  green(0xFF6BCB77),
  blue(0xFF5FA8F5),
  pink(0xFFF28BB6),
  purple(0xFFB08BE8);

  const ReaderAnnotationColor(this.argb);

  /// Opaque ARGB value used when rendering this color.
  final int argb;

  String get wireName => name;

  static ReaderAnnotationColor fromWire(Object? wire) {
    if (wire is String) {
      for (final color in values) {
        if (color.name == wire) return color;
      }
    }
    return ReaderAnnotationColor.yellow;
  }
}

/// Immutable markup annotation (highlight / underline / strikethrough)
/// managed by TITAN Reader.
///
/// Geometry is stored as a list of [NormalizedPageRect] fragments covering the
/// selected text runs, which keeps the annotation accurate across zoom,
/// window, orientation and rendering-scale changes and distinguishes
/// duplicated text snippets by their exact page location.
@immutable
class ReaderAnnotation {
  /// Stable unique identifier.
  final String id;

  /// Identifier of the owning [ReaderDocument]-level entry.
  final String documentId;

  /// 1-based page carrying the annotation.
  final int pageNumber;

  /// Markup style.
  final ReaderAnnotationType type;

  /// Markup color.
  final ReaderAnnotationColor color;

  /// Selected text the annotation was created from. Retained for display and
  /// note association; geometry (not this string) is authoritative.
  final String selectedText;

  /// Normalized bounding fragments of the selected text.
  final List<NormalizedPageRect> rects;

  /// Creation timestamp. Injected by callers for deterministic tests.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  ReaderAnnotation({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.type,
    required this.selectedText,
    required List<NormalizedPageRect> rects,
    required this.createdAt,
    required this.updatedAt,
    this.color = ReaderAnnotationColor.yellow,
  })  : assert(pageNumber >= 1, 'pageNumber must be >= 1'),
        rects = List.unmodifiable(rects);

  /// Returns a copy with the given fields replaced; bumps nothing implicitly.
  ReaderAnnotation copyWith({
    ReaderAnnotationType? type,
    ReaderAnnotationColor? color,
    DateTime? updatedAt,
  }) {
    return ReaderAnnotation(
      id: id,
      documentId: documentId,
      pageNumber: pageNumber,
      type: type ?? this.type,
      color: color ?? this.color,
      selectedText: selectedText,
      rects: rects,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'type': type.wireName,
        'color': color.wireName,
        'selectedText': selectedText,
        'rects': rects.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserializes a [ReaderAnnotation]; throws [FormatException] on malformed
  /// required fields.
  factory ReaderAnnotation.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final documentId = json['documentId'];
    final pageNumber = json['pageNumber'];
    final selectedText = json['selectedText'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final rawRects = json['rects'];
    if (id is! String ||
        documentId is! String ||
        pageNumber is! int ||
        selectedText is! String ||
        createdAt is! String ||
        updatedAt is! String ||
        rawRects is! List) {
      throw const FormatException(
          'ReaderAnnotation JSON requires id, documentId, pageNumber, '
          'selectedText, rects, createdAt and updatedAt fields.');
    }
    return ReaderAnnotation(
      id: id,
      documentId: documentId,
      pageNumber: pageNumber,
      type: ReaderAnnotationType.fromWire(json['type']),
      color: ReaderAnnotationColor.fromWire(json['color']),
      selectedText: selectedText,
      rects: rawRects
          .whereType<Map<String, Object?>>()
          .map(NormalizedPageRect.fromJson)
          .toList(),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderAnnotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          type == other.type &&
          color == other.color &&
          selectedText == other.selectedText &&
          _rectsEqual(rects, other.rects) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  static bool _rectsEqual(
      List<NormalizedPageRect> a, List<NormalizedPageRect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, documentId, pageNumber, type, color,
      selectedText, Object.hashAll(rects), createdAt, updatedAt);

  @override
  String toString() =>
      'ReaderAnnotation(id: $id, page: $pageNumber, type: ${type.name})';
}
