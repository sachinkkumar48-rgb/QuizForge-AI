/// Authoritative Application Error (TITAN-KO-039.0 P39).
///
/// Typed error models and failure semantics for the Authoritative Learning-State
/// Application Gateway.
library;

import 'package:meta/meta.dart';

enum AuthoritativeApplicationErrorCode {
  examMismatch,
  learnerMismatch,
  fingerprintMismatch,
  staleState,
  alreadyApplied,
  invalidProposal,
  invalidState,
  persistenceFailure,
  verificationFailure,
  transactionFailure;

  String get serialName => name;

  static AuthoritativeApplicationErrorCode fromString(String val) {
    for (final code in values) {
      if (code.name.toLowerCase() == val.trim().toLowerCase()) {
        return code;
      }
    }
    throw ArgumentError(
        'Unknown AuthoritativeApplicationErrorCode: "$val". Valid: ${values.map((c) => c.name).toList()}');
  }
}

@immutable
class AuthoritativeApplicationError implements Exception {
  final AuthoritativeApplicationErrorCode code;
  final String message;
  final Map<String, dynamic> details;

  AuthoritativeApplicationError({
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

  factory AuthoritativeApplicationError.fromJson(Map<String, dynamic> json) {
    return AuthoritativeApplicationError(
      code:
          AuthoritativeApplicationErrorCode.fromString(json['code'] as String),
      message: json['message'] as String,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }

  @override
  String toString() =>
      'AuthoritativeApplicationError(${code.serialName}: $message${details.isNotEmpty ? ', details: $details' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthoritativeApplicationError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}
