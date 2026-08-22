import 'package:meta/meta.dart';

/// Rating level for OCR recognition confidence.
enum OcrConfidenceLevel {
  /// High recognition accuracy (>= 85%).
  high,

  /// Moderate recognition accuracy (60% - 84%).
  medium,

  /// Low recognition accuracy (< 60%), prone to noise or distortion.
  low,
}

/// Immutable value object representing OCR recognition confidence in the range [0.0, 1.0].
@immutable
class OcrConfidence implements Comparable<OcrConfidence> {
  /// The normalized confidence score between 0.0 (zero confidence) and 1.0 (perfect match).
  final double value;

  const OcrConfidence(double value)
      : value = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);

  /// 0% confidence constant.
  static const OcrConfidence zero = OcrConfidence(0.0);

  /// 100% confidence constant.
  static const OcrConfidence perfect = OcrConfidence(1.0);

  /// Returns the categorized confidence rating level.
  OcrConfidenceLevel get level {
    if (value >= 0.85) return OcrConfidenceLevel.high;
    if (value >= 0.60) return OcrConfidenceLevel.medium;
    return OcrConfidenceLevel.low;
  }

  /// Percentage string representation (e.g., "94.5%").
  String get percentageString => '${(value * 100).toStringAsFixed(1)}%';

  @override
  int compareTo(OcrConfidence other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrConfidence &&
          runtimeType == other.runtimeType &&
          (value - other.value).abs() < 1e-6;

  @override
  int get hashCode => (value * 1000).round().hashCode;

  @override
  String toString() => 'OcrConfidence($percentageString, level: ${level.name})';

  Map<String, Object?> toJson() => {'value': value};

  factory OcrConfidence.fromJson(Map<String, Object?> json) {
    final v = (json['value'] as num?)?.toDouble() ?? 0.0;
    return OcrConfidence(v);
  }
}
