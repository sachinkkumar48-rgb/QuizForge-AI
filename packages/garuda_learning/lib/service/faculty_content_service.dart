/// Faculty Content Service (TITAN-KO-045.0 P45).
///
/// Central application domain service managing the faculty content creation,
/// validation, versioning, publication, and learner synchronization pipeline.
library;

import 'package:garuda_pyq/garuda_pyq.dart' show NormalizedQuestion;

import '../domain/entities/content_origin.dart';
import '../domain/entities/content_validation_result.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/managed_content_item.dart';
import '../repository/faculty_content_repository.dart';
import '../repository/remedial_lesson_repository.dart';
import 'curriculum_service.dart';

class FacultyContentService {
  final FacultyContentRepository _contentRepository;
  final CurriculumService _curriculumService;
  final RemedialLessonRepository? _remedialRepository;

  FacultyContentService({
    required FacultyContentRepository contentRepository,
    required CurriculumService curriculumService,
    RemedialLessonRepository? remedialRepository,
  })  : _contentRepository = contentRepository,
        _curriculumService = curriculumService,
        _remedialRepository = remedialRepository;

  FacultyContentRepository get contentRepository => _contentRepository;
  CurriculumService get curriculumService => _curriculumService;
  RemedialLessonRepository? get remedialRepository => _remedialRepository;

  /// Creates a new draft managed content item.
  Future<ManagedContentItem> createDraft({
    required String id,
    required String title,
    String description = '',
    required String examId,
    required String subjectId,
    required String topicId,
    required String objectiveId,
    required ManagedContentType contentType,
    required String authorId,
    String authorName = 'Faculty Contributor',
    required String provenance,
    ContentOrigin contentOrigin = ContentOrigin.pedagogicalExplanation,
    String prompt = '',
    List<String> options = const [],
    String correctAnswer = '',
    String explanation = '',
    String difficulty = 'Medium',
    String summary = '',
    List<String> learningPoints = const [],
    String lessonExplanation = '',
    List<String> examples = const [],
    List<String> misconceptions = const [],
    int estimatedMinutes = 10,
    Map<String, dynamic> metadata = const {},
  }) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError('Content ID cannot be empty');
    }

    // Check duplicate ID protection
    final existing = await _contentRepository.getById(cleanId);
    if (existing != null) {
      throw StateError('Content with ID "$cleanId" already exists');
    }

    final now = DateTime.now().toUtc();
    final item = ManagedContentItem(
      id: cleanId,
      title: title.trim(),
      description: description.trim(),
      examId: examId.trim(),
      subjectId: subjectId.trim(),
      topicId: topicId.trim(),
      objectiveId: objectiveId.trim(),
      contentType: contentType,
      authorId: authorId.trim(),
      authorName: authorName.trim(),
      provenance: provenance.trim(),
      contentOrigin: contentOrigin,
      status: ContentLifecycleStatus.draft,
      version: 1,
      createdAt: now,
      updatedAt: now,
      prompt: prompt.trim(),
      options: options.map((o) => o.trim()).toList(),
      correctAnswer: correctAnswer.trim(),
      explanation: explanation.trim(),
      difficulty: difficulty,
      summary: summary.trim(),
      learningPoints: learningPoints.map((p) => p.trim()).toList(),
      lessonExplanation: lessonExplanation.trim(),
      examples: examples,
      misconceptions: misconceptions,
      estimatedMinutes: estimatedMinutes,
      metadata: metadata,
    );

    await _contentRepository.save(item);
    return item;
  }

  /// Updates an existing draft or creates a new version draft if the item was already published.
  Future<ManagedContentItem> updateDraft(ManagedContentItem updated) async {
    final existing = await _contentRepository.getById(updated.id);
    if (existing == null) {
      throw StateError('Cannot update non-existent content "${updated.id}"');
    }

    final now = DateTime.now().toUtc();

    if (existing.status == ContentLifecycleStatus.published) {
      // Create new draft revision (v2) preserving v1 published version intact
      final nextVersion = existing.version + 1;
      final newDraft = updated.copyWith(
        version: nextVersion,
        status: ContentLifecycleStatus.draft,
        updatedAt: now,
        validationErrors: const [],
      );
      await _contentRepository.save(newDraft);
      return newDraft;
    } else {
      // In-place update of draft / validation-failed / ready-to-publish
      final updatedItem = updated.copyWith(
        updatedAt: now,
        status: ContentLifecycleStatus.draft,
        validationErrors: const [],
      );
      await _contentRepository.save(updatedItem);
      return updatedItem;
    }
  }

  /// Validates a content item deterministically against curriculum and educational rules.
  ContentValidationResult validateContent(ManagedContentItem item) {
    final errors = <String>[];
    final warnings = <String>[];

    // Rule 6.1: Empty title
    if (item.title.trim().isEmpty) {
      errors.add('Content title cannot be empty.');
    }

    // Rule 6.2: Missing hierarchy mappings
    if (item.examId.trim().isEmpty) {
      errors.add('Exam mapping cannot be empty.');
    }
    if (item.subjectId.trim().isEmpty) {
      errors.add('Subject mapping cannot be empty.');
    }
    if (item.topicId.trim().isEmpty) {
      errors.add('Topic mapping cannot be empty.');
    }
    if (item.objectiveId.trim().isEmpty) {
      errors.add('Learning objective mapping cannot be empty.');
    } else {
      // Rule 6.3 & 13: Valid objective in curriculum framework
      final obj = _curriculumService.getObjectiveById(item.objectiveId);
      if (obj == null) {
        errors.add('Objective ID "${item.objectiveId}" does not exist in curriculum framework.');
      }
    }

    // Rule 6.4: Provenance validation
    if (item.provenance.trim().isEmpty) {
      errors.add('Source citation / provenance cannot be empty.');
    }

    // Rule 11: PYQ Safety Invariant
    if (item.id.toUpperCase().startsWith('PYQ_') ||
        item.metadata.containsKey('isOfficialPyqAnswer')) {
      errors.add('Official PYQ answer keys and provenance are immutable and protected.');
    }

    // Content-Type specific validations
    if (item.contentType == ManagedContentType.question) {
      if (item.prompt.trim().isEmpty) {
        errors.add('Question prompt cannot be empty.');
      }
      if (item.options.length < 2) {
        errors.add('Question must contain at least 2 selectable options.');
      }
      if (item.options.any((o) => o.trim().isEmpty)) {
        errors.add('All question options must be non-empty.');
      }
      if (item.correctAnswer.trim().isEmpty) {
        errors.add('Correct answer must be specified.');
      } else {
        // Validate answer matches an option (either exact string or letter A, B, C...)
        bool matched = false;
        final ansTrim = item.correctAnswer.trim();
        final ansUpper = ansTrim.toUpperCase();

        if (ansUpper.length == 1 &&
            ansUpper.codeUnitAt(0) >= 65 &&
            ansUpper.codeUnitAt(0) < 65 + item.options.length) {
          matched = true;
        } else {
          matched = item.options.any((o) => o.trim().toLowerCase() == ansTrim.toLowerCase());
        }

        if (!matched) {
          errors.add('Correct answer "$ansTrim" does not match any available option.');
        }
      }
    } else {
      // Remedial lesson / Learning Material
      final hasExplanation = item.lessonExplanation.trim().isNotEmpty ||
          item.explanation.trim().isNotEmpty ||
          item.summary.trim().isNotEmpty;
      if (!hasExplanation) {
        errors.add('Remedial lesson or learning material must contain pedagogical explanation or summary.');
      }
      if (item.estimatedMinutes <= 0 || item.estimatedMinutes > 180) {
        warnings.add('Estimated duration (${item.estimatedMinutes} min) is outside typical range [1, 180].');
      }
    }

    if (errors.isNotEmpty) {
      return ContentValidationResult.failure(errors, warnings: warnings);
    }
    return ContentValidationResult.success(warnings: warnings);
  }

  /// Validates and publishes a content item, synchronizing it to learner-facing discovery.
  Future<ManagedContentItem> publishContent(String id) async {
    final item = await _contentRepository.getById(id);
    if (item == null) {
      throw StateError('Cannot publish non-existent content "$id"');
    }

    final validation = validateContent(item);
    final now = DateTime.now().toUtc();

    if (!validation.isValid) {
      final failedItem = item.copyWith(
        status: ContentLifecycleStatus.validationFailed,
        validationErrors: validation.errors,
        updatedAt: now,
      );
      await _contentRepository.save(failedItem);
      throw StateError('Content validation failed: ${validation.errors.join(", ")}');
    }

    final publishedItem = item.copyWith(
      status: ContentLifecycleStatus.published,
      validationErrors: const [],
      updatedAt: now,
    );

    await _contentRepository.save(publishedItem);

    // Synchronize to learner-facing repositories
    if (publishedItem.contentType == ManagedContentType.remedialLesson) {
      final remRepo = _remedialRepository;
      if (remRepo != null) {
        await remRepo.saveLesson(publishedItem.toRemedialLesson());
      }
    }

    return publishedItem;
  }

  /// Unpublishes an item, hiding it from learner discovery.
  Future<ManagedContentItem> unpublishContent(String id) async {
    final item = await _contentRepository.getById(id);
    if (item == null) {
      throw StateError('Cannot unpublish non-existent content "$id"');
    }

    final now = DateTime.now().toUtc();
    final unpublishedItem = item.copyWith(
      status: ContentLifecycleStatus.unpublished,
      updatedAt: now,
    );

    await _contentRepository.save(unpublishedItem);

    if (unpublishedItem.contentType == ManagedContentType.remedialLesson) {
      final remRepo = _remedialRepository;
      if (remRepo != null) {
        await remRepo.deleteLesson(unpublishedItem.id);
      }
    }

    return unpublishedItem;
  }

  /// Returns runtime [NormalizedQuestion] objects for all published faculty questions.
  Future<List<NormalizedQuestion>> getPublishedQuestions({String? topicName}) async {
    final List<ManagedContentItem> items;
    if (topicName != null && topicName.isNotEmpty) {
      items = await _contentRepository.getPublishedQuestionsForTopic(topicName);
    } else {
      items = await _contentRepository.getAll(
        contentType: ManagedContentType.question,
        status: ContentLifecycleStatus.published,
      );
    }

    return items.map((i) => i.toNormalizedQuestion()).toList();
  }

  /// Retrieves curriculum objectives for a selected topic name.
  List<LearningObjective> getObjectivesForTopic(String topicName) {
    final tLower = topicName.trim().toLowerCase();
    return _curriculumService.framework.allObjectives.where((obj) {
      return obj.description.toLowerCase().contains(tLower) ||
          obj.title.toLowerCase().contains(tLower) ||
          obj.unitId.toLowerCase().contains(tLower);
    }).toList();
  }
}
