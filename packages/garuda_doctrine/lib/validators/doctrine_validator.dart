library;

import 'package:meta/meta.dart';
import '../domain/entities/doctrine_knowledge_object.dart';
import '../repositories/doctrine_repository.dart';

@immutable
class DoctrineValidationError {
  final String code;
  final String message;
  final String doctrineId;

  const DoctrineValidationError({
    required this.code,
    required this.message,
    required this.doctrineId,
  });

  @override
  String toString() => '[$code] ($doctrineId): $message';
}

@immutable
class DoctrineValidationResult {
  final bool isValid;
  final List<DoctrineValidationError> errors;

  const DoctrineValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  factory DoctrineValidationResult.success() =>
      const DoctrineValidationResult(isValid: true);

  factory DoctrineValidationResult.failure(List<DoctrineValidationError> errors) =>
      DoctrineValidationResult(isValid: false, errors: errors);
}

/// Comprehensive Validation Engine for Constitutional Doctrine Knowledge Objects.
class DoctrineValidator {
  static Future<DoctrineValidationResult> validateRepository(
      DoctrineRepository repository) async {
    final errors = <DoctrineValidationError>[];
    final doctrines = await repository.getDoctrines();

    final seenIds = <String>{};
    final seenNames = <String>{};

    for (final d in doctrines) {
      // 1. Unique Object ID check
      if (d.objectId.trim().isEmpty) {
        errors.add(DoctrineValidationError(
          code: 'EMPTY_DOCTRINE_ID',
          message: 'Doctrine object ID cannot be empty.',
          doctrineId: d.objectId,
        ));
      } else if (seenIds.contains(d.objectId)) {
        errors.add(DoctrineValidationError(
          code: 'DUPLICATE_DOCTRINE_ID',
          message: 'Duplicate Doctrine objectId "${d.objectId}" detected.',
          doctrineId: d.objectId,
        ));
      } else {
        seenIds.add(d.objectId);
      }

      // 2. Duplicate Name Check
      final cleanName = d.name.trim().toLowerCase();
      if (cleanName.isNotEmpty) {
        if (seenNames.contains(cleanName)) {
          errors.add(DoctrineValidationError(
            code: 'DUPLICATE_DOCTRINE_NAME',
            message: 'Duplicate doctrine name "${d.name}" detected.',
            doctrineId: d.objectId,
          ));
        } else {
          seenNames.add(cleanName);
        }
      } else {
        errors.add(DoctrineValidationError(
          code: 'MISSING_DOCTRINE_NAME',
          message: 'Doctrine name cannot be empty.',
          doctrineId: d.objectId,
        ));
      }

      // 3. Definition & Origin Completeness Check
      if (d.officialDefinition.trim().isEmpty) {
        errors.add(DoctrineValidationError(
          code: 'MISSING_DEFINITION',
          message: 'Official definition cannot be empty.',
          doctrineId: d.objectId,
        ));
      }

      if (d.originatingCase.trim().isEmpty) {
        errors.add(DoctrineValidationError(
          code: 'MISSING_ORIGINATING_CASE',
          message: 'Originating case cannot be empty.',
          doctrineId: d.objectId,
        ));
      }

      // 4. Evidence References for Approved Objects
      if (d.editorialStatus == 'APPROVED' &&
          d.evidenceReferences.isEmpty &&
          d.citations.isEmpty &&
          d.primarySource.trim().isEmpty) {
        errors.add(DoctrineValidationError(
          code: 'MISSING_EVIDENCE',
          message: 'Approved Doctrine Knowledge Object must contain citations or evidence references.',
          doctrineId: d.objectId,
        ));
      }

      // 5. Broken PYQ Link check
      for (final pyq in d.pyqIds) {
        if (!pyq.startsWith('PYQ_')) {
          errors.add(DoctrineValidationError(
            code: 'BROKEN_PYQ_LINK',
            message: 'PYQ ID "$pyq" does not follow standard "PYQ_" prefix format.',
            doctrineId: d.objectId,
          ));
        }
      }
    }

    if (errors.isNotEmpty) {
      return DoctrineValidationResult.failure(errors);
    }

    return DoctrineValidationResult.success();
  }
}
