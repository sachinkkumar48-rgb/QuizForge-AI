import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'normalized_page_rect.dart';

/// Represents a 2D coordinate point in PDF user space units (points, bottom-left origin).
@immutable
class PdfPoint {
  final double x;
  final double y;

  const PdfPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPoint &&
          (other.x - x).abs() < 1e-4 &&
          (other.y - y).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(x.toStringAsFixed(3), y.toStringAsFixed(3));

  @override
  String toString() =>
      'PdfPoint(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// Represents an axis-aligned bounding box [llx, lly, urx, ury] in PDF user space (bottom-left origin).
@immutable
class PdfBoundingBox {
  final double left; // llx
  final double bottom; // lly
  final double right; // urx
  final double top; // ury

  const PdfBoundingBox({
    required this.left,
    required this.bottom,
    required this.right,
    required this.top,
  });

  double get width => (right - left).abs();
  double get height => (top - bottom).abs();

  /// Normalizes coordinates so left <= right and bottom <= top.
  PdfBoundingBox normalized() {
    return PdfBoundingBox(
      left: math.min(left, right),
      bottom: math.min(bottom, top),
      right: math.max(left, right),
      top: math.max(bottom, top),
    );
  }

  /// Expands this box to enclose [other].
  PdfBoundingBox union(PdfBoundingBox other) {
    final a = normalized();
    final b = other.normalized();
    return PdfBoundingBox(
      left: math.min(a.left, b.left),
      bottom: math.min(a.bottom, b.bottom),
      right: math.max(a.right, b.right),
      top: math.max(a.top, b.top),
    );
  }

  /// Converts this bounding box to a standard 4-element PDF rectangle list `[llx, lly, urx, ury]`.
  List<double> toPdfRect() {
    final norm = normalized();
    return [norm.left, norm.bottom, norm.right, norm.top];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfBoundingBox &&
          (other.left - left).abs() < 1e-4 &&
          (other.bottom - bottom).abs() < 1e-4 &&
          (other.right - right).abs() < 1e-4 &&
          (other.top - top).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(
      left.toStringAsFixed(2),
      bottom.toStringAsFixed(2),
      right.toStringAsFixed(2),
      top.toStringAsFixed(2));

  @override
  String toString() =>
      'PdfBoundingBox(L:${left.toStringAsFixed(1)}, B:${bottom.toStringAsFixed(1)}, R:${right.toStringAsFixed(1)}, T:${top.toStringAsFixed(1)})';
}

/// Represents an 8-number quadrilateral specifying 4 vertices in PDF user space (ISO 32000-1 §12.5.6.10).
/// Order: (x1, y1) = Top-Left, (x2, y2) = Top-Right, (x3, y3) = Bottom-Left, (x4, y4) = Bottom-Right.
@immutable
class PdfQuadPoint {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x3;
  final double y3;
  final double x4;
  final double y4;

  const PdfQuadPoint({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.x3,
    required this.y3,
    required this.x4,
    required this.y4,
  });

  /// Factory from a bounding box in PDF points (bottom-left origin).
  factory PdfQuadPoint.fromBox(PdfBoundingBox box) {
    final norm = box.normalized();
    return PdfQuadPoint(
      x1: norm.left,
      y1: norm.top, // Top-Left
      x2: norm.right,
      y2: norm.top, // Top-Right
      x3: norm.left,
      y3: norm.bottom, // Bottom-Left
      x4: norm.right,
      y4: norm.bottom, // Bottom-Right
    );
  }

  /// Converts this quadpoint to an 8-number list for the PDF `/QuadPoints` array.
  List<double> toList() => [x1, y1, x2, y2, x3, y3, x4, y4];

  /// Computes the axis-aligned bounding box enclosing this quad.
  PdfBoundingBox computeBoundingBox() {
    final minX = math.min(math.min(x1, x2), math.min(x3, x4));
    final maxX = math.max(math.max(x1, x2), math.max(x3, x4));
    final minY = math.min(math.min(y1, y2), math.min(y3, y4));
    final maxY = math.max(math.max(y1, y2), math.max(y3, y4));
    return PdfBoundingBox(left: minX, bottom: minY, right: maxX, top: maxY);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfQuadPoint &&
          (other.x1 - x1).abs() < 1e-4 &&
          (other.y1 - y1).abs() < 1e-4 &&
          (other.x2 - x2).abs() < 1e-4 &&
          (other.y2 - y2).abs() < 1e-4 &&
          (other.x3 - x3).abs() < 1e-4 &&
          (other.y3 - y3).abs() < 1e-4 &&
          (other.x4 - x4).abs() < 1e-4 &&
          (other.y4 - y4).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(x1.toStringAsFixed(2), y1.toStringAsFixed(2),
      x2.toStringAsFixed(2), y2.toStringAsFixed(2));
}

/// Authoritative coordinate transformation service between TITAN's canonical
/// [NormalizedPageRect] (0..1, top-left origin) and PDF Page Points (bottom-left origin).
class PdfCoordinateTransformer {
  /// Converts a [NormalizedPageRect] into a [PdfBoundingBox] for a page of [pageWidth] x [pageHeight].
  static PdfBoundingBox normalizedToPdfBox(
    NormalizedPageRect rect, {
    required double pageWidth,
    required double pageHeight,
  }) {
    final left = rect.left * pageWidth;
    final right = rect.right * pageWidth;
    final top = (1.0 - rect.top) * pageHeight;
    final bottom = (1.0 - rect.bottom) * pageHeight;

    return PdfBoundingBox(
      left: left,
      bottom: math.min(bottom, top),
      right: right,
      top: math.max(bottom, top),
    );
  }

  /// Converts a [NormalizedPageRect] into a [PdfQuadPoint] for a page of [pageWidth] x [pageHeight].
  static PdfQuadPoint normalizedToPdfQuad(
    NormalizedPageRect rect, {
    required double pageWidth,
    required double pageHeight,
  }) {
    final box =
        normalizedToPdfBox(rect, pageWidth: pageWidth, pageHeight: pageHeight);
    return PdfQuadPoint.fromBox(box);
  }

  /// Converts a [PdfBoundingBox] (points, bottom-left origin) into a [NormalizedPageRect] (0..1, top-left origin).
  static NormalizedPageRect pdfBoxToNormalized(
    PdfBoundingBox box, {
    required double pageWidth,
    required double pageHeight,
  }) {
    if (pageWidth <= 0 || pageHeight <= 0) {
      return const NormalizedPageRect(left: 0, top: 0, right: 1, bottom: 1);
    }
    final norm = box.normalized();
    final left = (norm.left / pageWidth).clamp(0.0, 1.0);
    final right = (norm.right / pageWidth).clamp(0.0, 1.0);
    final top = (1.0 - (norm.top / pageHeight)).clamp(0.0, 1.0);
    final bottom = (1.0 - (norm.bottom / pageHeight)).clamp(0.0, 1.0);

    return NormalizedPageRect(
      left: left,
      top: math.min(top, bottom),
      right: right,
      bottom: math.max(top, bottom),
    );
  }

  /// Converts a [PdfQuadPoint] into a [NormalizedPageRect].
  static NormalizedPageRect pdfQuadToNormalized(
    PdfQuadPoint quad, {
    required double pageWidth,
    required double pageHeight,
  }) {
    final box = quad.computeBoundingBox();
    return pdfBoxToNormalized(box,
        pageWidth: pageWidth, pageHeight: pageHeight);
  }

  /// Converts normalized ink points `[0..1, 0..1]` (top-left origin) into [PdfPoint]s (bottom-left origin).
  static List<PdfPoint> normalizedStrokeToPdfPoints(
    List<math.Point<double>> stroke, {
    required double pageWidth,
    required double pageHeight,
  }) {
    return stroke.map((p) {
      final pdfX = p.x * pageWidth;
      final pdfY = (1.0 - p.y) * pageHeight;
      return PdfPoint(pdfX, pdfY);
    }).toList();
  }

  /// Converts [PdfPoint]s into normalized points `[0..1, 0..1]`.
  static List<math.Point<double>> pdfPointsToNormalizedStroke(
    List<PdfPoint> points, {
    required double pageWidth,
    required double pageHeight,
  }) {
    if (pageWidth <= 0 || pageHeight <= 0) return const [];
    return points.map((p) {
      final normX = (p.x / pageWidth).clamp(0.0, 1.0);
      final normY = (1.0 - (p.y / pageHeight)).clamp(0.0, 1.0);
      return math.Point<double>(normX, normY);
    }).toList();
  }
}
