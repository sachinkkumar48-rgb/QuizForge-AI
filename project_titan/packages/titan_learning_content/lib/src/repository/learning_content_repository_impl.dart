import '../integration/content_engine_integrator.dart';
import '../models/learning_content_models.dart';
import 'learning_content_repository.dart';

/// Concrete implementation of [LearningContentRepository] providing offline-first
/// caching, progress tracking, and cross-engine synchronization.
class LearningContentRepositoryImpl implements LearningContentRepository {
  final ContentEngineIntegrator integrator;
  final Map<String, LearningContent> _memoryStore = {};
  final Map<String, LearningContent> _offlineCache = {};
  final Map<String, ContentProgress> _progressStore =
      {}; // Key: '${userId}_${contentId}'
  final Map<String, ContentCompletion> _completionStore =
      {}; // Key: '${userId}_${contentId}'

  LearningContentRepositoryImpl({
    ContentEngineIntegrator? integrator,
    List<LearningContent>? initialContents,
  }) : integrator = integrator ?? const ContentEngineIntegrator() {
    if (initialContents != null && initialContents.isNotEmpty) {
      for (final item in initialContents) {
        _memoryStore[item.id] = item;
        _offlineCache[item.id] = item;
      }
    } else {
      _seedDefaultCatalog();
    }
  }

  void _seedDefaultCatalog() {
    final videoContent = LearningContent(
      id: 'lc_video_01',
      title: 'Preamble & Constitutional Philosophy',
      description:
          'Video lecture analyzing sovereign, socialist, secular, democratic, republic principles.',
      type: ContentType.video,
      chapterId: 'chap_p1_1',
      courseId: 'course_polity_101',
      knowledgeNodeId: 'node_polity_preamble',
      metadata: ContentMetadata(
        author: 'Dr. M. Laxmikanth',
        subject: 'Polity',
        topic: 'Indian Polity',
        difficultyLevel: 'Intermediate',
        estimatedDurationMinutes: 30,
        format: 'mp4_hd',
        fileSizeFormat: '145 MB',
        tags: const ['Preamble', 'Constitution', 'Polity'],
        isOfflineAvailable: true,
      ),
      objectives: const [
        ContentObjective(
          id: 'obj_1',
          title: 'Analyze Preamble Keywords',
          description: 'Understand legal implications of Preamble terminology.',
          bloomsTaxonomyLevel: 'Analyze',
        ),
      ],
      prerequisites: const [
        ContentPrerequisite(
          id: 'pre_1',
          requiredContentId: 'lc_notes_01',
          title: 'Historical Background Notes',
        ),
      ],
      outcomes: const [
        ContentOutcome(
          id: 'out_1',
          title: 'Preamble Mastery',
          description:
              'Ability to answer UPSC Prelims and Mains questions on Preamble.',
          masteryGain: 15.0,
          skillBadge: 'Polity Scholar',
        ),
      ],
      references: const [
        LearningContentReference(
          id: 'ref_1',
          contentId: 'lc_video_01',
          title: 'Supreme Court Preamble Judgments PDF',
          contentType: ContentType.pdf,
          uri: 'assets/pdf/preamble_cases.pdf',
          type: 'pdf',
        ),
      ],
    );

    final pdfContent = LearningContent(
      id: 'lc_pdf_01',
      title: 'Fundamental Rights Landmark Judgments Digest',
      description:
          'Comprehensive PDF reference summarizing Articles 12-35 court cases.',
      type: ContentType.pdf,
      chapterId: 'chap_p1_1',
      courseId: 'course_polity_101',
      knowledgeNodeId: 'node_polity_rights',
      metadata: ContentMetadata(
        author: 'TITAN Legal Research Wing',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        difficultyLevel: 'Advanced',
        estimatedDurationMinutes: 45,
        format: 'pdf',
        fileSizeFormat: '12 MB',
        tags: const ['Fundamental Rights', 'Judgments', 'Articles 12-35'],
        isOfflineAvailable: true,
      ),
      objectives: const [
        ContentObjective(
          id: 'obj_2',
          title: 'Evaluate Basic Structure Doctrine',
          description:
              'Analyze Kesavananda Bharati & Minerva Mills precedents.',
          bloomsTaxonomyLevel: 'Evaluate',
        ),
      ],
      prerequisites: const [],
      outcomes: const [
        ContentOutcome(
          id: 'out_2',
          title: 'Constitutional Law Proficiency',
          description:
              'Deep understanding of fundamental rights jurisprudence.',
          masteryGain: 20.0,
        ),
      ],
      references: const [],
    );

    final quizContent = LearningContent(
      id: 'lc_quiz_01',
      title: 'Polity Prelims PYQ Practice Session',
      description:
          'Interactive quiz containing 15 UPSC PYQs on Preamble and Fundamental Rights.',
      type: ContentType.pyq,
      chapterId: 'chap_p1_1',
      courseId: 'course_polity_101',
      knowledgeNodeId: 'node_polity_quiz',
      metadata: ContentMetadata(
        author: 'TITAN Quiz Engine',
        subject: 'Polity',
        topic: 'Indian Polity',
        difficultyLevel: 'Intermediate',
        estimatedDurationMinutes: 20,
        format: 'interactive_quiz',
        tags: const ['PYQ', 'Prelims', 'Polity'],
        isOfflineAvailable: true,
      ),
      objectives: const [
        ContentObjective(
          id: 'obj_3',
          title: 'Test Exam Readiness',
          description: 'Solve past year questions with 80%+ accuracy.',
          bloomsTaxonomyLevel: 'Apply',
        ),
      ],
      prerequisites: const [],
      outcomes: const [],
      references: const [],
    );

    _memoryStore[videoContent.id] = videoContent;
    _memoryStore[pdfContent.id] = pdfContent;
    _memoryStore[quizContent.id] = quizContent;

    _offlineCache[videoContent.id] = videoContent;
    _offlineCache[pdfContent.id] = pdfContent;
    _offlineCache[quizContent.id] = quizContent;
  }

  @override
  Future<LearningContent?> getContentById(String id) async {
    return _memoryStore[id] ?? _offlineCache[id];
  }

  @override
  Future<List<LearningContent>> getChapterContents(String chapterId) async {
    return _memoryStore.values.where((c) => c.chapterId == chapterId).toList();
  }

  @override
  Future<ContentProgress> updateProgress({
    required String userId,
    required String contentId,
    required int lastPositionSeconds,
    required double completionPercentage,
    required int timeSpentSeconds,
  }) async {
    final content = await getContentById(contentId);
    if (content == null) {
      throw ArgumentError('Content with id $contentId not found');
    }

    final key = '${userId}_$contentId';
    final existingProgress = _progressStore[key];
    final totalSpent =
        (existingProgress?.timeSpentSeconds ?? 0) + timeSpentSeconds;
    final isDone = completionPercentage >= 100.0;

    final updatedProgress = ContentProgress(
      contentId: contentId,
      userId: userId,
      lastPositionSeconds: lastPositionSeconds,
      completionPercentage: completionPercentage,
      timeSpentSeconds: totalSpent,
      lastAccessedAt: DateTime.now(),
      isCompleted: isDone,
    );

    _progressStore[key] = updatedProgress;

    // Attach updated progress to memory model
    _memoryStore[contentId] = content.copyWith(progress: updatedProgress);

    if (isDone) {
      await markCompleted(userId: userId, contentId: contentId);
    }

    return updatedProgress;
  }

  @override
  Future<ContentCompletion> markCompleted({
    required String userId,
    required String contentId,
    double? score,
    String? feedback,
  }) async {
    final content = await getContentById(contentId);
    if (content == null) {
      throw ArgumentError('Content with id $contentId not found');
    }

    final key = '${userId}_$contentId';
    final existingCompletion = _completionStore[key];
    final attempts = (existingCompletion?.totalAttempts ?? 0) + 1;

    final completion = ContentCompletion(
      contentId: contentId,
      userId: userId,
      completedAt: DateTime.now(),
      score: score,
      totalAttempts: attempts,
      feedback: feedback,
    );

    _completionStore[key] = completion;

    final currentProgress = _progressStore[key] ??
        ContentProgress(
          contentId: contentId,
          userId: userId,
          completionPercentage: 100.0,
          timeSpentSeconds: 60,
          lastAccessedAt: DateTime.now(),
          isCompleted: true,
        );

    _memoryStore[contentId] = content.copyWith(
      completion: completion,
      progress: currentProgress.copyWith(
          isCompleted: true, completionPercentage: 100.0),
    );

    // Sync across TITAN engines
    await integrator.syncContentCompletion(
      userId: userId,
      content: content,
      progress: currentProgress,
    );

    return completion;
  }

  @override
  Future<List<ContentObjective>> getObjectives(String contentId) async {
    final content = await getContentById(contentId);
    return content?.objectives ?? const [];
  }

  @override
  Future<List<ContentPrerequisite>> getPrerequisites(String contentId) async {
    final content = await getContentById(contentId);
    return content?.prerequisites ?? const [];
  }

  @override
  Future<List<ContentOutcome>> getOutcomes(String contentId) async {
    final content = await getContentById(contentId);
    return content?.outcomes ?? const [];
  }

  @override
  Future<LearningContent?> getCachedContent(String contentId) async {
    return _offlineCache[contentId];
  }

  @override
  Future<void> syncContent({required String userId}) async {
    // Synchronize offline progress cache with cloud storage / engines
    for (final entry in _progressStore.entries) {
      final content = _memoryStore[entry.value.contentId];
      if (content != null) {
        _offlineCache[content.id] = content;
      }
    }
  }
}
