import 'package:meta/meta.dart';

/// Value object representing the validation and execution status of a PYQ
/// ingestion operation in TITAN PIE.
@immutable
class PYQValidationResult {
  /// Whether the validation or ingestion overall succeeded.
  final bool success;

  /// List of non-fatal warnings captured during parsing, validation, or mapping.
  final List<String> warnings;

  /// List of fatal errors that prevented successful processing.
  final List<String> errors;

  /// Execution metrics and statistics map (e.g. processedCount, executionTimeMs).
  final Map<String, dynamic> statistics;

  /// Constructs an immutable [PYQValidationResult].
  PYQValidationResult({
    required this.success,
    List<String> warnings = const [],
    List<String> errors = const [],
    Map<String, dynamic> statistics = const {},
  })  : warnings = List<String>.unmodifiable(warnings),
        errors = List<String>.unmodifiable(errors),
        statistics = Map<String, dynamic>.unmodifiable(statistics);

  /// Returns `true` if operation was successful and contains zero fatal errors.
  bool get isValid => success && errors.isEmpty;

  /// Returns `true` if non-fatal warnings are present.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Returns `true` if fatal errors are present.
  bool get hasErrors => errors.isNotEmpty;

  /// Creates a copy of this [PYQValidationResult] with updated fields.
  PYQValidationResult copyWith({
    bool? success,
    List<String>? warnings,
    List<String>? errors,
    Map<String, dynamic>? statistics,
  }) {
    return PYQValidationResult(
      success: success ?? this.success,
      warnings: warnings ?? this.warnings,
      errors: errors ?? this.errors,
      statistics: statistics ?? this.statistics,
    );
  }

  /// Converts this result into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'warnings': warnings,
      'errors': errors,
      'statistics': statistics,
      'isValid': isValid,
    };
  }

  /// Deserializes a [PYQValidationResult] from a Map.
  factory PYQValidationResult.fromMap(Map<String, dynamic> map) {
    return PYQValidationResult(
      success: (map['success'] as bool?) ?? false,
      warnings: List<String>.from(map['warnings'] as List? ?? const []),
      errors: List<String>.from(map['errors'] as List? ?? const []),
      statistics:
          Map<String, dynamic>.from(map['statistics'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PYQValidationResult &&
        other.success == success &&
        _listEquals(other.warnings, warnings) &&
        _listEquals(other.errors, errors) &&
        _mapEquals(other.statistics, statistics);
  }

  @override
  int get hashCode {
    return Object.hash(
      success,
      Object.hashAll(warnings),
      Object.hashAll(errors),
      Object.hashAll(statistics.keys),
      Object.hashAll(statistics.values),
    );
  }

  @override
  String toString() {
    return 'PYQValidationResult(success: $success, isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
