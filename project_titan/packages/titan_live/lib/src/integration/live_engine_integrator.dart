import 'package:titan_ai_mentor/titan_ai_mentor.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_content/titan_learning_content.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_notes/titan_notes.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_video/titan_video.dart';

import '../models/live_models.dart';

/// Integration bridge service connecting `titan_live` with AI Mentor, Learning Content,
/// Video, Smart Notes, Knowledge Graph, Planner, Analytics, Learning Profile, and Search.
class LiveEngineIntegrator {
  final AskMentorUseCase? askMentorUseCase;
  final GetLearningProfileUseCase? getLearningProfileUseCase;
  final LearningProfileRepository? learningProfileRepository;
  final StudyPlannerEngine? plannerEngine;
  final GenerateRecommendationsUseCase? recommendationUseCase;
  final KnowledgeGraphEngine? knowledgeGraphEngine;
  final SearchRepository? searchRepository;
  final SmartNotesEngine? notesEngine;
  final NotesRepository? notesRepository;
  final VideoPlaybackEngine? videoPlaybackEngine;

  const LiveEngineIntegrator({
    this.askMentorUseCase,
    this.getLearningProfileUseCase,
    this.learningProfileRepository,
    this.plannerEngine,
    this.recommendationUseCase,
    this.knowledgeGraphEngine,
    this.searchRepository,
    this.notesEngine,
    this.notesRepository,
    this.videoPlaybackEngine,
  });

  // ==========================================
  // AI MENTOR INTEGRATION
  // ==========================================

  /// AI Mentor: Explains teacher discussion in real-time.
  Future<MentorMessage?> explainTeacherDiscussion({
    required String userId,
    required String discussionSnippet,
  }) async {
    final prompt =
        'Explain this live lecture discussion snippet for a UPSC aspirant: "$discussionSnippet"';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'AI Live Explanation: Explains core constitutional principles and precedents.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Summarizes live session.
  Future<MentorMessage?> summarizeSession({
    required String userId,
    required LiveSession session,
  }) async {
    final prompt =
        'Summarize live class session "${session.id}" key points and discussion highlights.';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Live Class Summary: Article 21 scope, Puttaswamy 9-judge ruling, and Maneka Gandhi test.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Answers live question from student.
  Future<MentorMessage?> answerLiveQuestion({
    required String userId,
    required String question,
  }) async {
    final prompt = 'Answer live student query concisely: "$question"';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'AI Live Answer: Right to Privacy is an intrinsic part of Right to Life under Art 21.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  // ==========================================
  // LEARNING CONTENT & VIDEO INTEGRATION
  // ==========================================

  /// Converts live recording into canonical `LearningContent` without duplicating models.
  LearningContent convertRecordingToLearningContent(
    LiveClass liveClass,
    Recording recording,
  ) {
    final durationMins = (recording.durationSeconds / 60).round();
    final metadata = ContentMetadata(
      author: liveClass.instructorName,
      subject: liveClass.subjectCategory,
      topic: liveClass.title,
      difficultyLevel: 'Intermediate',
      estimatedDurationMinutes: durationMins > 0 ? durationMins : 60,
      format: 'mp4',
      tags: [liveClass.subjectCategory, 'LIVE_RECORDING'],
      isOfflineAvailable: true,
    );

    return LearningContent(
      id: recording.learningContentId ?? 'lc_rec_${recording.id}',
      title: 'Recorded Class: ${liveClass.title}',
      description: liveClass.description,
      type: ContentType.liveClass,
      metadata: metadata,
      objectives: const [
        ContentObjective(
          id: 'obj_1',
          title: 'Live Lecture Mastery',
          description: 'Master live lecture concepts and case laws.',
          bloomsTaxonomyLevel: 'Understand',
        ),
      ],
      prerequisites: const [],
      outcomes: const [],
      references: const [],
    );
  }

  // ==========================================
  // SMART NOTES INTEGRATION
  // ==========================================

  /// Creates a live note linked to the active session.
  SmartNote createLiveNote({
    required String id,
    required LiveClass liveClass,
    required String content,
    int? timestampSeconds,
  }) {
    final now = DateTime.now();
    return SmartNote(
      id: id,
      title: 'Live Note: ${liveClass.title}',
      content: content,
      type: timestampSeconds != null ? NoteType.timestamp : NoteType.manual,
      contentId: liveClass.id,
      timestampSeconds: timestampSeconds,
      knowledgeNodeIds: liveClass.knowledgeNodeIds,
      sections: const [],
      tags: [
        const NoteTag(id: 't_live', label: 'LIVE_CLASS'),
        NoteTag(id: 't_subj', label: liveClass.subjectCategory.toUpperCase()),
      ],
      attachments: const [],
      bookmarks: const [],
      versions: const [],
      comments: const [],
      references: [
        NoteReference(
          id: 'ref_live_${now.millisecondsSinceEpoch}',
          targetType: 'liveClass',
          targetId: liveClass.id,
          displayTitle: liveClass.title,
          timestampSeconds: timestampSeconds,
        ),
      ],
      highlights: const [],
      annotations: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Converts whiteboard snapshot into a smart note annotation.
  SmartNote createWhiteboardNote({
    required String id,
    required LiveClass liveClass,
    required WhiteboardSnapshot snapshot,
  }) {
    final now = DateTime.now();
    return SmartNote(
      id: id,
      title: 'Whiteboard: ${snapshot.title}',
      content: 'Captured from live class by ${snapshot.capturedBy}',
      type: NoteType.pdf,
      contentId: liveClass.id,
      knowledgeNodeIds: liveClass.knowledgeNodeIds,
      sections: const [],
      tags: const [NoteTag(id: 't_wb', label: 'WHITEBOARD')],
      attachments: const [],
      bookmarks: const [],
      versions: const [],
      comments: const [],
      references: const [],
      highlights: const [],
      annotations: [
        Annotation(
          id: 'ann_${snapshot.id}',
          contentId: liveClass.id,
          author: snapshot.capturedBy,
          text: snapshot.title,
          createdAt: snapshot.capturedAt,
          pageNumber: 1,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==========================================
  // KNOWLEDGE GRAPH INTEGRATION
  // ==========================================

  /// Creates a KnowledgeNode representing the live class concept.
  KnowledgeNode createKnowledgeNodeForClass(LiveClass liveClass) {
    return KnowledgeNode(
      id: 'node_live_${liveClass.id}',
      title: liveClass.title,
      type: KnowledgeNodeType.topic,
      description: liveClass.description,
      subjectCategory: liveClass.subjectCategory,
      masteryWeight: 0.85,
    );
  }

  // ==========================================
  // PLANNER INTEGRATION
  // ==========================================

  /// Schedules live class into user daily study planner.
  StudyTask scheduleClassInPlanner(LiveClass liveClass) {
    final duration = liveClass.schedule.scheduledEndTime
        .difference(liveClass.schedule.scheduledStartTime)
        .inMinutes;

    return StudyTask(
      id: 'task_live_${liveClass.id}',
      title: 'LIVE CLASS: ${liveClass.title}',
      topic: liveClass.subjectCategory,
      category: 'Live Class',
      priority: 'High',
      estimatedDurationMinutes: duration > 0 ? duration : 60,
      isCompleted: false,
    );
  }

  // ==========================================
  // SEARCH INTEGRATION
  // ==========================================

  /// Indexes live class metadata, transcript, chat, and whiteboard for semantic search.
  Future<void> indexLiveClassForSearch(LiveClass liveClass) async {
    if (searchRepository == null) return;

    final session = liveClass.activeSession;
    final chatText =
        session?.chatMessages.map((c) => c.message).join(' ') ?? '';
    final wbText =
        session?.whiteboardSnapshots.map((w) => w.title).join(' ') ?? '';

    final fullText = '${liveClass.title} ${liveClass.description} '
        'Instructor: ${liveClass.instructorName} $chatText $wbText';

    final indexItem = SearchIndexItem(
      id: 'idx_live_${liveClass.id}',
      contentId: liveClass.id,
      title: liveClass.title,
      content: fullText,
      scope: SearchScope.notes,
      conceptIds: liveClass.knowledgeNodeIds,
      tags: [liveClass.subjectCategory, 'LIVE_CLASS'],
      timestamp: liveClass.createdAt,
      metadata: {
        'instructorName': liveClass.instructorName,
        'subjectCategory': liveClass.subjectCategory,
        'scheduledStartTime':
            liveClass.schedule.scheduledStartTime.toIso8601String(),
      },
    );

    await searchRepository!.indexItem(indexItem);
  }

  // ==========================================
  // LEARNING PROFILE & ANALYTICS INTEGRATION
  // ==========================================

  /// Updates student learning profile attendance and study time.
  Future<void> updateProfileAttendance({
    required String userId,
    required int watchDurationMinutes,
  }) async {
    if (getLearningProfileUseCase == null ||
        learningProfileRepository == null) {
      return;
    }
    final profile = await getLearningProfileUseCase!.execute(userId: userId);

    final updated = profile.copyWith(
      totalStudyTimeMinutes:
          profile.totalStudyTimeMinutes + watchDurationMinutes,
      lastActiveAt: DateTime.now(),
    );

    await learningProfileRepository!.saveLearningProfile(updated);
  }
}
