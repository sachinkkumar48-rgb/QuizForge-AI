import 'package:titan_ai_mentor/titan_ai_mentor.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';
import 'package:titan_search/titan_search.dart';

import '../models/notes_models.dart';

/// Integration bridge service connecting `titan_notes` with AI Mentor, Knowledge Graph,
/// Recommendation, Planner, Analytics, Learning Profile, Search, and Revision.
class NotesEngineIntegrator {
  final AskMentorUseCase? askMentorUseCase;
  final GetLearningProfileUseCase? getLearningProfileUseCase;
  final LearningProfileRepository? learningProfileRepository;
  final StudyPlannerEngine? plannerEngine;
  final GenerateRecommendationsUseCase? recommendationUseCase;
  final KnowledgeGraphEngine? knowledgeGraphEngine;
  final SearchRepository? searchRepository;
  final SpacedRepetitionEngine? revisionEngine;
  final ResultAnalyticsRepository? analyticsRepository;

  const NotesEngineIntegrator({
    this.askMentorUseCase,
    this.getLearningProfileUseCase,
    this.learningProfileRepository,
    this.plannerEngine,
    this.recommendationUseCase,
    this.knowledgeGraphEngine,
    this.searchRepository,
    this.revisionEngine,
    this.analyticsRepository,
  });

  // ==========================================
  // AI FEATURES INTEGRATION
  // ==========================================

  /// AI Mentor: Explains note content.
  Future<MentorMessage?> explainNote({
    required String userId,
    required SmartNote note,
  }) async {
    final prompt =
        'Explain and elaborate on this study note "${note.title}": ${note.content}';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'AI Explanation for "${note.title}": Covers core principles for UPSC Mains.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Improves note clarity and structure.
  Future<MentorMessage?> improveNote({
    required String userId,
    required SmartNote note,
  }) async {
    final prompt =
        'Improve readability, clarity, and formatting of note "${note.title}".';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Improved Note Suggestion for "${note.title}": Structured into key bullet points.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Expands note with deep domain context.
  Future<MentorMessage?> expandNote({
    required String userId,
    required SmartNote note,
  }) async {
    final prompt =
        'Expand note "${note.title}" with UPSC GS Paper historical and legal context.';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Expanded Context for "${note.title}": Detailed constitutional provisions and landmark cases.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Simplifies complex note text.
  Future<MentorMessage?> simplifyNote({
    required String userId,
    required SmartNote note,
  }) async {
    final prompt =
        'Simplify this complex note into easy language: "${note.content}"';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Simplified Summary: Key takeaways expressed in plain language.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Converts note to flashcards.
  Future<MentorMessage?> convertToFlashcards({
    required String userId,
    required SmartNote note,
  }) async {
    final prompt =
        'Convert note "${note.title}" into active-recall flashcard pairs (Q&A).';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Flashcards generated for "${note.title}": Q1: What is the core ruling? A1: Kesavananda Bharati case.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Converts note to a self-assessment quiz.
  Future<MentorMessage?> convertToQuiz({
    required String userId,
    required SmartNote note,
  }) async {
    final prompt =
        'Generate multiple choice quiz questions based on "${note.title}".';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Quiz generated for "${note.title}": 1. Which case law established basic structure?',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Generates bulleted revision notes.
  Future<MentorMessage?> generateRevisionNotes({
    required String userId,
    required SmartNote note,
  }) async {
    final prompt =
        'Generate high-yield revision bullet points from note "${note.title}".';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Revision Notes for "${note.title}": Key Articles, SC Rulings, Amendments.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Generates structured summary.
  Future<NoteSummary> generateSummary(SmartNote note) async {
    final lines = note.content.split('\n').where((l) => l.isNotEmpty).toList();
    return NoteSummary(
      overview: lines.isNotEmpty ? lines.first : note.title,
      keyTakeaways: lines.length > 1
          ? lines.sublist(1, lines.length > 4 ? 4 : lines.length)
          : [note.title],
      upscRelevance: const ['Direct relevance to UPSC GS Papers.'],
    );
  }

  // ==========================================
  // VIDEO INTEGRATION
  // ==========================================

  /// Video: Creates a timestamped note.
  SmartNote createTimestampNote({
    required String id,
    required String videoId,
    required String title,
    required String content,
    required int timestampSeconds,
  }) {
    final now = DateTime.now();
    return SmartNote(
      id: id,
      title: title,
      content: content,
      type: NoteType.timestamp,
      contentId: videoId,
      timestampSeconds: timestampSeconds,
      knowledgeNodeIds: const [],
      sections: const [],
      tags: const [NoteTag(id: 't_video', label: 'VIDEO')],
      attachments: const [],
      bookmarks: const [],
      versions: const [],
      comments: const [],
      references: [
        NoteReference(
          id: 'ref_v_${DateTime.now().millisecondsSinceEpoch}',
          targetType: 'video',
          targetId: videoId,
          displayTitle: '$title @ ${timestampSeconds}s',
          timestampSeconds: timestampSeconds,
        ),
      ],
      highlights: const [],
      annotations: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Video: Creates a transcript snippet note.
  SmartNote createTranscriptNote({
    required String id,
    required String videoId,
    required String transcriptSnippet,
    required int timestampSeconds,
  }) {
    final now = DateTime.now();
    return SmartNote(
      id: id,
      title: 'Transcript Snippet @ ${timestampSeconds}s',
      content: transcriptSnippet,
      type: NoteType.transcript,
      contentId: videoId,
      timestampSeconds: timestampSeconds,
      knowledgeNodeIds: const [],
      sections: const [],
      tags: const [NoteTag(id: 't_transcript', label: 'TRANSCRIPT')],
      attachments: const [],
      bookmarks: const [],
      versions: const [],
      comments: const [],
      references: const [],
      highlights: const [],
      annotations: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==========================================
  // PDF INTEGRATION
  // ==========================================

  /// PDF: Creates a PDF page note.
  SmartNote createPdfPageNote({
    required String id,
    required String pdfId,
    required int pageNumber,
    required String title,
    required String content,
  }) {
    final now = DateTime.now();
    return SmartNote(
      id: id,
      title: title,
      content: content,
      type: NoteType.pdf,
      contentId: pdfId,
      pageNumber: pageNumber,
      knowledgeNodeIds: const [],
      sections: const [],
      tags: const [NoteTag(id: 't_pdf', label: 'PDF')],
      attachments: const [],
      bookmarks: const [],
      versions: const [],
      comments: const [],
      references: [
        NoteReference(
          id: 'ref_pdf_${DateTime.now().millisecondsSinceEpoch}',
          targetType: 'pdf',
          targetId: pdfId,
          displayTitle: '$title (Page $pageNumber)',
          pageNumber: pageNumber,
        ),
      ],
      highlights: const [],
      annotations: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==========================================
  // KNOWLEDGE GRAPH INTEGRATION
  // ==========================================

  /// Knowledge Graph: Maps note to a KnowledgeNode.
  KnowledgeNode createKnowledgeNodeForNote(SmartNote note) {
    return KnowledgeNode(
      id: 'node_note_${note.id}',
      title: note.title,
      type: KnowledgeNodeType.concept,
      description: note.content,
      subjectCategory:
          note.tags.isNotEmpty ? note.tags.first.label : 'General Studies',
      masteryWeight: 0.8,
    );
  }

  /// Knowledge Graph: Links note to Concept, Topic, Chapter, or PYQ.
  SmartNote linkNoteToReference({
    required SmartNote note,
    required String targetType, // 'concept', 'topic', 'chapter', 'pyq'
    required String targetId,
    required String displayTitle,
  }) {
    final newRef = NoteReference(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      targetType: targetType,
      targetId: targetId,
      displayTitle: displayTitle,
    );

    final updatedRefs = List<NoteReference>.from(note.references)..add(newRef);
    return note.copyWith(
      references: updatedRefs,
      updatedAt: DateTime.now(),
    );
  }

  // ==========================================
  // SEARCH INTEGRATION
  // ==========================================

  /// Search: Indexes note for semantic search in `titan_search`.
  Future<void> indexNoteForSearch(SmartNote note) async {
    if (searchRepository == null) return;

    final fullText =
        '${note.title} ${note.content} ${note.summary?.overview ?? ''} '
        '${note.highlights.map((h) => h.highlightedText).join(' ')}';

    final indexItem = SearchIndexItem(
      id: 'idx_note_${note.id}',
      contentId: note.id,
      title: note.title,
      content: fullText,
      scope: SearchScope.notes,
      conceptIds: note.knowledgeNodeIds,
      tags: note.tags.map((t) => t.label).toList(),
      timestamp: note.updatedAt,
      metadata: {
        'type': note.type.name,
        'timestampSeconds': note.timestampSeconds,
        'pageNumber': note.pageNumber,
      },
    );

    await searchRepository!.indexItem(indexItem);
  }

  // ==========================================
  // REVISION INTEGRATION
  // ==========================================

  /// Revision: Generates revision item for spaced repetition.
  RevisionItem createRevisionItemForNote(SmartNote note) {
    final now = DateTime.now();
    return RevisionItem(
      id: 'rev_note_${note.id}',
      topic: note.title,
      subtopic:
          note.tags.isNotEmpty ? note.tags.first.label : 'General Studies',
      questionText: note.content,
      lastReviewedAt: now,
      nextReviewDate: now.add(const Duration(days: 1)),
      intervalDays: 1,
      repetitions: 1,
      easeFactor: 2.5,
      sourceTag: 'Smart Notes Engine',
    );
  }

  // ==========================================
  // PLANNER INTEGRATION
  // ==========================================

  /// Planner Integration: Schedules note review task.
  StudyTask createPlannerTaskForNoteReview(SmartNote note) {
    return StudyTask(
      id: 'task_review_note_${note.id}',
      title: 'Review Note: ${note.title}',
      topic: note.tags.isNotEmpty ? note.tags.first.label : 'General',
      category: 'Note Revision',
      priority: 'Medium',
      estimatedDurationMinutes: 15,
      isCompleted: false,
    );
  }

  // ==========================================
  // PROFILE & ANALYTICS INTEGRATION
  // ==========================================

  /// Profile Sync: Updates study time when creating/revising notes.
  Future<void> syncNoteActivityToProfile({
    required String userId,
    required SmartNote note,
    required int minutesSpent,
  }) async {
    if (getLearningProfileUseCase == null ||
        learningProfileRepository == null) {
      return;
    }
    final profile = await getLearningProfileUseCase!.execute(userId: userId);

    final updated = profile.copyWith(
      totalStudyTimeMinutes: profile.totalStudyTimeMinutes + minutesSpent,
      lastActiveAt: DateTime.now(),
    );

    await learningProfileRepository!.saveLearningProfile(updated);
  }
}
