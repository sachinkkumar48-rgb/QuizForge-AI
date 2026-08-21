import 'package:meta/meta.dart';

/// Supported types of visual signatures in TITAN Reader.
enum PdfSignatureType {
  /// Hand-drawn stroke path signature captured via canvas.
  drawn,

  /// Stylized text signature rendered in cursive script typography.
  typed,

  /// Imported raster/vector image signature with alpha transparency.
  image,
}

/// A 2D point with normalized coordinates (0.0 to 1.0) representing a point in a signature stroke.
@immutable
class PdfSignaturePoint {
  final double x;
  final double y;

  const PdfSignaturePoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory PdfSignaturePoint.fromJson(Map<String, dynamic> json) {
    return PdfSignaturePoint(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfSignaturePoint &&
          (other.x - x).abs() < 1e-4 &&
          (other.y - y).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(x.toStringAsFixed(3), y.toStringAsFixed(3));

  @override
  String toString() =>
      'PdfSignaturePoint(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// Immutable domain model representing a saved visual signature artifact.
@immutable
class PdfVisualSignature {
  /// Unique identifier (e.g. UUID).
  final String id;

  /// User-visible label (e.g. "Primary Signature", "Initials").
  final String name;

  /// Signature creation type.
  final PdfSignatureType type;

  /// Normalized stroke paths for drawn signatures.
  final List<List<PdfSignaturePoint>> strokes;

  /// Text content for typed signatures.
  final String typedText;

  /// Stylized font presentation key for typed signatures (e.g. 'cursive', 'formal', 'casual').
  final String fontStyle;

  /// Base64 encoded image data for imported image signatures.
  final String imageBase64;

  /// Primary color value in ARGB integer format (default: black).
  final int colorArgb;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  const PdfVisualSignature({
    required this.id,
    required this.name,
    required this.type,
    this.strokes = const [],
    this.typedText = '',
    this.fontStyle = 'cursive',
    this.imageBase64 = '',
    this.colorArgb = 0xFF000000,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for a drawn signature.
  factory PdfVisualSignature.drawn({
    required String id,
    required String name,
    required List<List<PdfSignaturePoint>> strokes,
    int colorArgb = 0xFF000000,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return PdfVisualSignature(
      id: id,
      name: name,
      type: PdfSignatureType.drawn,
      strokes: strokes,
      colorArgb: colorArgb,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Factory for a typed signature.
  factory PdfVisualSignature.typed({
    required String id,
    required String name,
    required String text,
    String fontStyle = 'cursive',
    int colorArgb = 0xFF000000,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return PdfVisualSignature(
      id: id,
      name: name,
      type: PdfSignatureType.typed,
      typedText: text,
      fontStyle: fontStyle,
      colorArgb: colorArgb,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Factory for an image signature.
  factory PdfVisualSignature.image({
    required String id,
    required String name,
    required String imageBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return PdfVisualSignature(
      id: id,
      name: name,
      type: PdfSignatureType.image,
      imageBase64: imageBase64,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Whether the signature contains sufficient data to be usable.
  bool get isValid {
    if (name.trim().isEmpty) return false;
    switch (type) {
      case PdfSignatureType.drawn:
        return strokes.isNotEmpty && strokes.any((s) => s.isNotEmpty);
      case PdfSignatureType.typed:
        return typedText.trim().isNotEmpty;
      case PdfSignatureType.image:
        return imageBase64.trim().isNotEmpty;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'strokes':
            strokes.map((s) => s.map((p) => p.toJson()).toList()).toList(),
        'typedText': typedText,
        'fontStyle': fontStyle,
        'imageBase64': imageBase64,
        'colorArgb': colorArgb,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PdfVisualSignature.fromJson(Map<String, dynamic> json) {
    return PdfVisualSignature(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled Signature',
      type: PdfSignatureType.values.byName(json['type'] as String),
      strokes: (json['strokes'] as List<dynamic>?)
              ?.map((s) => (s as List<dynamic>)
                  .map((p) =>
                      PdfSignaturePoint.fromJson(p as Map<String, dynamic>))
                  .toList())
              .toList() ??
          const [],
      typedText: json['typedText'] as String? ?? '',
      fontStyle: json['fontStyle'] as String? ?? 'cursive',
      imageBase64: json['imageBase64'] as String? ?? '',
      colorArgb: json['colorArgb'] as int? ?? 0xFF000000,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  PdfVisualSignature copyWith({
    String? id,
    String? name,
    PdfSignatureType? type,
    List<List<PdfSignaturePoint>>? strokes,
    String? typedText,
    String? fontStyle,
    String? imageBase64,
    int? colorArgb,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PdfVisualSignature(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      strokes: strokes ?? this.strokes,
      typedText: typedText ?? this.typedText,
      fontStyle: fontStyle ?? this.fontStyle,
      imageBase64: imageBase64 ?? this.imageBase64,
      colorArgb: colorArgb ?? this.colorArgb,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfVisualSignature &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          colorArgb == other.colorArgb &&
          typedText == other.typedText &&
          fontStyle == other.fontStyle &&
          imageBase64 == other.imageBase64;

  @override
  int get hashCode => Object.hash(id, name, type, colorArgb, typedText);
}
