library;

import 'package:meta/meta.dart';
import '../domain/entities/article_knowledge_object.dart';
import '../domain/entities/constitution_knowledge_object.dart';
import '../domain/entities/part_knowledge_object.dart';
import '../domain/entities/schedule_knowledge_object.dart';
import '../repositories/constitution_repository.dart';

@immutable
class ConstitutionValidationError {
  final String code;
  final String message;
  final String objectId;

  const ConstitutionValidationError({
    required this.code,
    required this.message,
    required this.objectId,
  });

  @override
  String toString() => '[$code] ($objectId): $message';
}

@immutable
class ConstitutionValidationResult {
  final bool isValid;
  final List<ConstitutionValidationError> errors;

  const ConstitutionValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  factory ConstitutionValidationResult.success() =>
      const ConstitutionValidationResult(isValid: true);

  factory ConstitutionValidationResult.failure(
          List<ConstitutionValidationError> errors) =>
      ConstitutionValidationResult(isValid: false, errors: errors);
}

/// Comprehensive Validation Engine for Constitution Knowledge Objects.
/// Validates ID uniqueness, structural metadata completeness, cross-links, and reference integrity.
class ConstitutionValidator {
  static Future<ConstitutionValidationResult> validateRepository(
      ConstitutionRepository repository) async {
    final errors = <ConstitutionValidationError>[];

    final preamble = await repository.getPreamble();
    final parts = await repository.getParts();
    final schedules = await repository.getSchedules();
    final articles = await repository.getArticles();

    final allObjects = <ConstitutionKnowledgeObject>[
      preamble,
      ...parts,
      ...schedules,
      ...articles,
    ];

    final seenIds = <String>{};
    final seenPartNumbers = <String>{};
    final seenScheduleNumbers = <String>{};
    final seenArticleNumbers = <String>{};

    for (final obj in allObjects) {
      // 1. Unique ID check
      if (obj.objectId.trim().isEmpty) {
        errors.add(ConstitutionValidationError(
          code: 'EMPTY_OBJECT_ID',
          message: 'Object ID cannot be empty.',
          objectId: obj.objectId,
        ));
      } else if (seenIds.contains(obj.objectId)) {
        errors.add(ConstitutionValidationError(
          code: 'DUPLICATE_OBJECT_ID',
          message: 'Duplicate objectId "${obj.objectId}" detected.',
          objectId: obj.objectId,
        ));
      } else {
        seenIds.add(obj.objectId);
      }

      // 2. Missing Metadata Check
      if (obj.title.trim().isEmpty) {
        errors.add(ConstitutionValidationError(
          code: 'MISSING_METADATA_TITLE',
          message: 'Object title cannot be empty.',
          objectId: obj.objectId,
        ));
      }
      if (obj.officialName.trim().isEmpty) {
        errors.add(ConstitutionValidationError(
          code: 'MISSING_METADATA_OFFICIAL_NAME',
          message: 'Object officialName cannot be empty.',
          objectId: obj.objectId,
        ));
      }
      if (obj.description.trim().isEmpty) {
        errors.add(ConstitutionValidationError(
          code: 'MISSING_METADATA_DESCRIPTION',
          message: 'Object description cannot be empty.',
          objectId: obj.objectId,
        ));
      }

      // 3. Duplicate Part / Schedule / Article Number Checks
      if (obj is PartKnowledgeObject) {
        if (seenPartNumbers.contains(obj.partNumber)) {
          errors.add(ConstitutionValidationError(
            code: 'DUPLICATE_PART_NUMBER',
            message: 'Duplicate Part number "${obj.partNumber}" detected.',
            objectId: obj.objectId,
          ));
        } else {
          seenPartNumbers.add(obj.partNumber);
        }
      } else if (obj is ScheduleKnowledgeObject) {
        if (seenScheduleNumbers.contains(obj.scheduleNumber)) {
          errors.add(ConstitutionValidationError(
            code: 'DUPLICATE_SCHEDULE_NUMBER',
            message: 'Duplicate Schedule number "${obj.scheduleNumber}" detected.',
            objectId: obj.objectId,
          ));
        } else {
          seenScheduleNumbers.add(obj.scheduleNumber);
        }
      } else if (obj is ArticleKnowledgeObject) {
        if (seenArticleNumbers.contains(obj.articleNumber)) {
          errors.add(ConstitutionValidationError(
            code: 'DUPLICATE_ARTICLE_NUMBER',
            message: 'Duplicate Article number "${obj.articleNumber}" detected.',
            objectId: obj.objectId,
          ));
        } else {
          seenArticleNumbers.add(obj.articleNumber);
        }

        // 4. Missing Bare Text
        if (obj.officialConstitutionalText.trim().isEmpty) {
          errors.add(ConstitutionValidationError(
            code: 'MISSING_BARE_TEXT',
            message: 'Official Constitutional Text cannot be empty.',
            objectId: obj.objectId,
          ));
        }

        // 5. Duplicate Case Law entries
        final seenCaseNames = <String>{};
        for (final c in obj.caseLaw) {
          final cName = c.caseName.toLowerCase().trim();
          if (cName.isNotEmpty) {
            if (seenCaseNames.contains(cName)) {
              errors.add(ConstitutionValidationError(
                code: 'DUPLICATE_CASE_LAW',
                message: 'Duplicate case law entry "${c.caseName}" in article.',
                objectId: obj.objectId,
              ));
            } else {
              seenCaseNames.add(cName);
            }
          }
        }

        // 6. Duplicate Amendment entries
        final seenAmdNames = <String>{};
        for (final a in obj.amendmentHistory) {
          final aName = a.amendmentName.toLowerCase().trim();
          if (aName.isNotEmpty) {
            if (seenAmdNames.contains(aName)) {
              errors.add(ConstitutionValidationError(
                code: 'DUPLICATE_AMENDMENT',
                message: 'Duplicate amendment record "${a.amendmentName}" in article.',
                objectId: obj.objectId,
              ));
            } else {
              seenAmdNames.add(aName);
            }
          }
        }

        // 7. Missing Evidence check for Approved items
        if (obj.editorialStatus == 'APPROVED' &&
            obj.evidenceReferences.isEmpty &&
            obj.citations.isEmpty) {
          errors.add(ConstitutionValidationError(
            code: 'MISSING_EVIDENCE',
            message: 'Approved Article Knowledge Object must contain citations or evidence references.',
            objectId: obj.objectId,
          ));
        }

        // 8. Broken PYQ Link check
        for (final pyq in obj.pyqIds) {
          if (!pyq.startsWith('PYQ_') && !pyq.startsWith('UPSC-')) {
            errors.add(ConstitutionValidationError(
              code: 'BROKEN_PYQ_LINK',
              message: 'PYQ ID "$pyq" does not follow standard "PYQ_" or "UPSC-" prefix format.',
              objectId: obj.objectId,
            ));
          }
        }
      }

      // 9. Broken Reference Checks (relatedParts, relatedSchedules)
      for (final relPart in obj.relatedParts) {
        if (relPart.startsWith('KO-PART-') && !allObjects.any((o) => o.objectId == relPart)) {
          errors.add(ConstitutionValidationError(
            code: 'BROKEN_PART_REFERENCE',
            message: 'Referenced Part "$relPart" does not exist in repository.',
            objectId: obj.objectId,
          ));
        }
      }

      for (final relSched in obj.relatedSchedules) {
        if (relSched.startsWith('KO-SCHED-') && !allObjects.any((o) => o.objectId == relSched)) {
          errors.add(ConstitutionValidationError(
            code: 'BROKEN_SCHEDULE_REFERENCE',
            message: 'Referenced Schedule "$relSched" does not exist in repository.',
            objectId: obj.objectId,
          ));
        }
      }

      // 10. Invalid Cross References Check
      for (final crossRef in obj.crossReferences) {
        if (crossRef.startsWith('KO-') && !allObjects.any((o) => o.objectId == crossRef)) {
          errors.add(ConstitutionValidationError(
            code: 'INVALID_CROSS_REFERENCE',
            message: 'Cross reference "$crossRef" does not exist in repository.',
            objectId: obj.objectId,
          ));
        }
      }
    }

    if (errors.isNotEmpty) {
      return ConstitutionValidationResult.failure(errors);
    }

    return ConstitutionValidationResult.success();
  }
}

