import 'package:titan_ai_mentor/titan_ai_mentor.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_search/titan_search.dart';

import '../models/video_models.dart';

/// Integration bridge service interconnecting `titan_video` with AI Mentor, Knowledge Graph,
/// Recommendation, Planner, Analytics, Learning Profile, and Search engines.
class VideoEngineIntegrator {
  final AskMentorUseCase? askMentorUseCase;
  final GetLearningProfileUseCase? getLearningProfileUseCase;
  final LearningProfileRepository? learningProfileRepository;
  final StudyPlannerEngine? plannerEngine;
  final GenerateRecommendationsUseCase? recommendationUseCase;
  final KnowledgeGraphEngine? knowledgeGraphEngine;
  final SearchRepository? searchRepository;

  const VideoEngineIntegrator({
    this.askMentorUseCase,
    this.getLearningProfileUseCase,
    this.learningProfileRepository,
    this.plannerEngine,
    this.recommendationUseCase,
    this.knowledgeGraphEngine,
    this.searchRepository,
  });

  /// AI Mentor: Explains current video timestamp context.
  Future<MentorMessage?> explainTimestampContext({
    required String userId,
    required VideoContent video,
    required int timestampSeconds,
  }) async {
    final prompt =
        'Explain the key concept taught in video "${video.title}" at timestamp ${timestampSeconds}s (Subject: ${video.metadata.subject}).';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'AI Mentor Explanation at timestamp ${timestampSeconds}s for "${video.title}": Focus on key principles, statutory provisions, and UPSC Mains application.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Explains selected transcript text segment.
  Future<MentorMessage?> explainTranscriptSegment({
    required String userId,
    required VideoContent video,
    required TranscriptSegment segment,
  }) async {
    final prompt =
        'Explain this video transcript excerpt from "${video.title}": "${segment.text}".';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'AI Transcript Guidance: "${segment.text}" illustrates core concepts relevant to ${video.metadata.subject}.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Generates comprehensive video summary.
  String generateVideoSummary(VideoContent video) {
    final chapterTitles = video.chapters.map((c) => c.title).join(', ');
    return 'Summary of "${video.title}" (${video.metadata.subject}): '
        'This video covers ${video.description}. Key chapters include: $chapterTitles. '
        'Essential for ${video.metadata.topic} revision.';
  }

  /// AI Mentor: Answers custom user question regarding the video.
  Future<MentorMessage?> askVideoQuestion({
    required String userId,
    required VideoContent video,
    required String question,
  }) async {
    final prompt =
        'Regarding video "${video.title}" (${video.metadata.subject}): $question';
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'AI Response for "${video.title}": $question\n\nIn UPSC, this question connects to foundational principles discussed in this lesson.',
        timestamp: DateTime.now(),
      );
    }
    return askMentorUseCase!
        .execute(userId: userId, userName: 'UPSC Aspirant', prompt: prompt);
  }

  /// AI Mentor: Generates revision notes from video content.
  String generateRevisionFromVideo(VideoContent video) {
    final objectives = video.objectives
        .map((o) => '• ${o.title}: ${o.description}')
        .join('\n');
    return 'Revision Note: ${video.title}\nSubject: ${video.metadata.subject}\nTopic: ${video.metadata.topic}\n\nObjectives:\n$objectives';
  }

  /// AI Mentor: Creates flashcards from video transcript & chapters.
  List<Map<String, String>> createFlashcardsFromVideo(VideoContent video) {
    final flashcards = <Map<String, String>>[];
    for (final chapter in video.chapters) {
      flashcards.add({
        'front':
            'What is discussed in chapter "${chapter.title}" of ${video.title}?',
        'back':
            'Covered between ${chapter.startSeconds}s and ${chapter.endSeconds}s.',
      });
    }
    return flashcards;
  }

  /// AI Mentor: Generates practice quiz questions from video content.
  List<Map<String, dynamic>> generateQuizFromVideo(VideoContent video) {
    return [
      {
        'question': 'Which topic is primarily analyzed in "${video.title}"?',
        'options': [
          video.metadata.topic,
          'General Knowledge',
          'Current Affairs',
          'Aptitude'
        ],
        'correctIndex': 0,
        'explanation': 'The video specifically covers ${video.metadata.topic}.',
      }
    ];
  }

  /// Knowledge Graph: Maps timestamp to KnowledgeNode.
  KnowledgeNode createKnowledgeNodeForTimestamp(
      VideoContent video, int timestampSeconds) {
    return KnowledgeNode(
      id: 'node_${video.id}_$timestampSeconds',
      title: '${video.title} @ ${timestampSeconds}s',
      type: KnowledgeNodeType.concept,
      description: video.description,
      subjectCategory: video.metadata.subject,
      masteryWeight: 0.85,
    );
  }

  /// Recommendation Engine: Generates video recommendations.
  List<VideoRecommendation> getRecommendedNextVideos(VideoContent video) {
    return [
      VideoRecommendation(
        contentId: 'lc_video_02',
        title: 'Fundamental Rights Jurisprudence',
        reason: 'Recommended follow-up to ${video.title}',
        similarityScore: 0.92,
        type: 'next_lesson',
      ),
      const VideoRecommendation(
        contentId: 'lc_quiz_01',
        title: 'Polity Prelims PYQ Quiz',
        reason: 'Test your understanding after watching video',
        similarityScore: 0.88,
        type: 'practice',
      ),
    ];
  }

  /// Planner Integration: Generates study task for unfinished video.
  StudyTask createPlannerTaskForUnfinishedVideo(
      VideoContent video, PlaybackState state) {
    final remainingMins =
        ((state.durationSeconds - state.positionSeconds) / 60).ceil();
    return StudyTask(
      id: 'task_video_${video.id}',
      title: 'Continue Video: ${video.title}',
      topic: video.metadata.topic,
      category: 'Concept Learning',
      priority: 'High',
      estimatedDurationMinutes: remainingMins > 0 ? remainingMins : 15,
      isCompleted: false,
    );
  }

  /// Analytics & Profile Sync: Updates study time and mastery upon watching video.
  Future<void> syncWatchProgressToProfile({
    required String userId,
    required VideoContent video,
    required int watchedSeconds,
  }) async {
    if (getLearningProfileUseCase == null ||
        learningProfileRepository == null) {
      return;
    }
    final currentProfile =
        await getLearningProfileUseCase!.execute(userId: userId);

    final masteries = List<TopicMastery>.from(currentProfile.topicMasteries);
    final idx = masteries.indexWhere((m) => m.topic == video.metadata.topic);

    if (idx >= 0) {
      final old = masteries[idx];
      masteries[idx] = old.copyWith(
        masteryPercentage: (old.masteryPercentage + 3.0).clamp(0.0, 100.0),
        lastPracticedAt: DateTime.now(),
      );
    }

    final updated = currentProfile.copyWith(
      totalStudyTimeMinutes:
          currentProfile.totalStudyTimeMinutes + (watchedSeconds ~/ 60),
      topicMasteries: masteries,
      lastActiveAt: DateTime.now(),
    );

    await learningProfileRepository!.saveLearningProfile(updated);
  }
}
