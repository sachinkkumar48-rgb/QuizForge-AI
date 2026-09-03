/// Authoritative Persistence Error (TITAN-KO-039.0 P39).
///
/// Typed error hierarchy for Authoritative Learning-State Persistence and Recovery.
library;

import 'package:meta/meta.dart';

/// Discrete error taxonomy for persistence operations.
enum AuthoritativePersistenceErrorCode {
  missingRequiredField,
  malformedPayload,
  unsupportedSchemaVersion,
  invalidEnumValue,
  invalidNumericValue,
  inconsistentState,
  staleWrite,
  corruptedChecksum,
  notFound,
  ioFailure;

  String get serialName => name;

  static AuthoritativePersistenceErrorCode fromString(String val) {
    for (final code in values) {
      if (code.name.toLowerCase() == val.trim().toLowerCase()) {
        return code;
      }
    }
    throw ArgumentError(
        'Unknown AuthoritativePersistenceErrorCode: "$val". Valid: ${values.map((c) => c.name).toList()}');
  }
}

/// Typed exception representing an authoritative persistence or recovery failure.
@immutable
class AuthoritativePersistenceException implements Exception {
  final AuthoritativePersistenceErrorCode code;
  final String message;
  final Map<String, dynamic> details;

  AuthoritativePersistenceException({
    required this.code,
    required this.message,
    Map<String, dynamic>? details,
  }) : details = details == null
            ? const {}
            : Map<String, dynamic>.unmodifiable(Map.from(details));

  Map<String, dynamic> toJson() => {
        'code': code.serialName,
        'message': message,
        if (details.isNotEmpty) 'details': details,
      };

  factory AuthoritativePersistenceException.fromJson(
      Map<String, dynamic> json) {
    return AuthoritativePersistenceException(
      code:
          AuthoritativePersistenceErrorCode.fromString(json['code'] as String),
      message: json['message'] as String,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }

  @override
  String toString() =>
      'AuthoritativePersistenceException(${code.serialName}: $message${details.isNotEmpty ? ', details: $details' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthoritativePersistenceException &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}
