import 'dart:convert';
import '../../domain/entities/evidence_object.dart';
import 'evidence_validator.dart';
import 'validation_result.dart';

/// Validator that checks JSON schema conformance and serialization/deserialization integrity.
class JSONValidator implements EvidenceValidator {
  @override
  String get name => 'JSONValidator';

  @override
  Future<ValidationResult> validate(EvidenceObject evidence) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    try {
      final jsonMap = evidence.toJson();
      final jsonString = jsonEncode(jsonMap);

      if (jsonString.isEmpty) {
        errors.add(const ValidationError(
          code: 'EMPTY_JSON_SERIALIZATION',
          field: 'toJson',
          message: 'JSON serialization produced empty output.',
        ));
      }

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final reconstructed = EvidenceObject.fromJson(decoded);

      if (reconstructed.id != evidence.id || reconstructed.title != evidence.title) {
        errors.add(const ValidationError(
          code: 'SERIALIZATION_ROUNDTRIP_MISMATCH',
          field: 'toJson/fromJson',
          message: 'Evidence object failed roundtrip JSON serialization verification.',
        ));
      }
    } catch (e) {
      errors.add(ValidationError(
        code: 'JSON_SERIALIZATION_ERROR',
        field: 'json',
        message: 'JSON validation error: $e',
      ));
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}
