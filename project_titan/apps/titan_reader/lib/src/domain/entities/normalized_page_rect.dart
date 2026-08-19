import 'package:meta/meta.dart';

/// Canonical annotation geometry expressed as a rectangle normalized against
/// the owning PDF page size.
///
/// All four values are fractions of the page dimensions in the range 0..1
/// with a top-left origin. Normalized coordinates are the Reader's canonical
/// position representation: they stay stable when zoom, window size, device,
/// orientation or page rendering scale change, because the mapping to any
/// concrete coordinate space is a pure multiplication with the current page
/// size. Never store raw screen coordinates as annotation positions.
///
/// Coordinate chain: PDF page coordinates -> normalized page coordinates
/// (persisted) -> viewport coordinates -> screen coordinates (render time).
@immutable
class NormalizedPageRect {
  /// Left edge as a fraction of the page width (0..1).
  final double left;

  /// Top edge as a fraction of the page height (0..1).
  final double top;

  /// Right edge as a fraction of the page width (0..1).
  final double right;

  /// Bottom edge as a fraction of the page height (0..1).
  final double bottom;

  const NormalizedPageRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  })  : assert(left >= 0 && left <= 1, 'left must be within 0..1'),
        assert(right >= 0 && right <= 1, 'right must be within 0..1'),
        assert(top >= 0 && top <= 1, 'top must be within 0..1'),
        assert(bottom >= 0 && bottom <= 1, 'bottom must be within 0..1'),
        assert(left <= right, 'left must be <= right'),
        assert(top <= bottom, 'top must be <= bottom');

  /// Fractional width of the rectangle.
  double get width => right - left;

  /// Fractional height of the rectangle.
  double get height => bottom - top;

  /// Scales this normalized rectangle to absolute coordinates for a page of
  /// the given [pageWidth] and [pageHeight].
  ///
  /// The result is independent of zoom level and viewport size; only the page
  /// dimensions matter.
  ScaledPageRect scaleTo(double pageWidth, double pageHeight) {
    assert(pageWidth > 0 && pageHeight > 0, 'page size must be positive');
    return ScaledPageRect(
      left: left * pageWidth,
      top: top * pageHeight,
      right: right * pageWidth,
      bottom: bottom * pageHeight,
    );
  }

  /// Creates a normalized rectangle from absolute PDF page coordinates.
  ///
  /// [pdfTop] must be measured from the top edge of the page (top-left
  /// origin), matching the Reader's canonical orientation.
  factory NormalizedPageRect.fromPageCoordinates({
    required double left,
    required double pdfTop,
    required double right,
    required double pdfBottom,
    required double pageWidth,
    required double pageHeight,
  }) {
    assert(pageWidth > 0 && pageHeight > 0, 'page size must be positive');
    double clamp(double v) => v.clamp(0.0, 1.0);
    final l = clamp(left / pageWidth);
    final r = clamp(right / pageWidth);
    final t = clamp(pdfTop / pageHeight);
    final b = clamp(pdfBottom / pageHeight);
    return NormalizedPageRect(
      left: l <= r ? l : r,
      right: l <= r ? r : l,
      top: t <= b ? t : b,
      bottom: t <= b ? b : t,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };

  /// Deserializes a [NormalizedPageRect]; throws [FormatException] on
  /// malformed or out-of-range values.
  factory NormalizedPageRect.fromJson(Map<String, Object?> json) {
    final left = json['left'];
    final top = json['top'];
    final right = json['right'];
    final bottom = json['bottom'];
    if (left is! num || top is! num || right is! num || bottom is! num) {
      throw const FormatException(
          'NormalizedPageRect JSON requires numeric left/top/right/bottom.');
    }
    return NormalizedPageRect(
      left: left.toDouble(),
      top: top.toDouble(),
      right: right.toDouble(),
      bottom: bottom.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizedPageRect &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() =>
      'NormalizedPageRect(l: $left, t: $top, r: $right, b: $bottom)';
}

/// Rectangle scaled to absolute coordinates inside a specific page.
///
/// Intermediate representation between the persisted normalized geometry and
/// concrete viewport/screen coordinates.
@immutable
class ScaledPageRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const ScaledPageRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;

  double get height => bottom - top;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaledPageRect &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() =>
      'ScaledPageRect(l: $left, t: $top, r: $right, b: $bottom)';
}
