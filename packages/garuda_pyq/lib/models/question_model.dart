import 'package:meta/meta.dart';

import '../concepts/cognitive_level.dart';
import '../concepts/question_nature.dart';
import '../editorial/learning_objectives_model.dart';
import '../editorial/question_trap_model.dart';
import 'answer_model.dart';
import 'editorial_review_model.dart';
import 'editorial_status.dart';
import 'option_model.dart';
import 'question_analytics_model.dart';
import 'source_model.dart';

enum QuestionType {
  mcq,
  assertionReason,
  matching,
  multipleCorrect,
  descriptive,
}

@immutable
class Question {
  final String id; // Permanent ID e.g. PYQ_UPSC_CSE_2024_GS1_Q001
  final int questionNumber;
  final String examId;
  final int year;
  final String stage;
  final String paper;
  final String? shift;
  final String subject;
  final String topic;
  final String? subtopic;
  final QuestionType questionType;
  final String originalQuestion;
  final List<Option> options;
  final Answer officialAnswer;
  final String garudaExplanation;
  final String difficulty; // Easy, Medium, Hard
  final String language; // en, hi
  final double marks;
  final double negativeMarks;
  final QuestionSource source;
  final String verificationStatus; // Verified, Unverified, Pending
  final EditorialStatus editorialStatus;
  final List<EditorialReview> editorialReviews;
  final QuestionAnalytics analytics;

  // Concept Mapping & Question Attributes (TITAN-PYQ-002)
  final List<String> conceptsTested;
  final CognitiveLevel cognitiveLevel;
  final QuestionNature questionNature;
  final double examWeight;
  final int frequency;

  // Editorial Production & Traps (TITAN-PYQ-003)
  final QuestionTrap? trap;
  final LearningObjectives? learningObjectives;
  final List<String> microConcepts;
  final List<String> coreConcepts;

  // Legal & Knowledge Links
  final List<String> knowledgeObjectLinks;
  final List<String> articleLinks;
  final List<String> actLinks;
  final List<String> caseLinks;
  final List<String> amendmentLinks;
  final List<String> committeeLinks;
  final List<String> reportLinks;
  final List<String> currentAffairsLinks;
  final List<String> relatedQuestionIds;
  final List<String> tags;

  final int version; // Knowledge Object Schema Version e.g. 1

  const Question({
    required this.id,
    this.questionNumber = 1,
    required this.examId,
    required this.year,
    required this.stage,
    required this.paper,
    this.shift,
    required this.subject,
    required this.topic,
    this.subtopic,
    this.questionType = QuestionType.mcq,
    required this.originalQuestion,
    required this.options,
    required this.officialAnswer,
    this.garudaExplanation = '',
    this.difficulty = 'Medium',
    this.language = 'en',
    this.version = 1,
    this.marks = 2.0,
    this.negativeMarks = 0.66,
    required this.source,
    this.verificationStatus = 'Verified',
    this.editorialStatus = EditorialStatus.readyForPublication,
    this.editorialReviews = const [],
    this.analytics = const QuestionAnalytics(),
    this.conceptsTested = const [],
    this.cognitiveLevel = CognitiveLevel.understand,
    this.questionNature = QuestionNature.conceptual,
    this.examWeight = 1.0,
    this.frequency = 1,
    this.trap,
    this.learningObjectives,
    this.microConcepts = const [],
    this.coreConcepts = const [],
    this.knowledgeObjectLinks = const [],
    this.articleLinks = const [],
    this.actLinks = const [],
    this.caseLinks = const [],
    this.amendmentLinks = const [],
    this.committeeLinks = const [],
    this.reportLinks = const [],
    this.currentAffairsLinks = const [],
    this.relatedQuestionIds = const [],
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionNumber': questionNumber,
        'examId': examId,
        'year': year,
        'stage': stage,
        'paper': paper,
        'shift': shift,
        'subject': subject,
        'topic': topic,
        'subtopic': subtopic,
        'questionType': questionType.name,
        'originalQuestion': originalQuestion,
        'options': options.map((o) => o.toJson()).toList(),
        'officialAnswer': officialAnswer.toJson(),
        'garudaExplanation': garudaExplanation,
        'difficulty': difficulty,
        'language': language,
        'version': version,
        'marks': marks,
        'negativeMarks': negativeMarks,
        'source': source.toJson(),
        'verificationStatus': verificationStatus,
        'editorialStatus': editorialStatus.name,
        'editorialReviews': editorialReviews.map((r) => r.toJson()).toList(),
        'analytics': analytics.toJson(),
        'conceptsTested': conceptsTested,
        'cognitiveLevel': cognitiveLevel.name,
        'questionNature': questionNature.name,
        'examWeight': examWeight,
        'frequency': frequency,
        'trap': trap?.toJson(),
        'learningObjectives': learningObjectives?.toJson(),
        'microConcepts': microConcepts,
        'coreConcepts': coreConcepts,
        'knowledgeObjectLinks': knowledgeObjectLinks,
        'articleLinks': articleLinks,
        'actLinks': actLinks,
        'caseLinks': caseLinks,
        'amendmentLinks': amendmentLinks,
        'committeeLinks': committeeLinks,
        'reportLinks': reportLinks,
        'currentAffairsLinks': currentAffairsLinks,
        'relatedQuestionIds': relatedQuestionIds,
        'tags': tags,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        questionNumber: (json['questionNumber'] as num?)?.toInt() ?? 1,
        examId: json['examId'] as String,
        year: json['year'] as int,
        stage: json['stage'] as String,
        paper: json['paper'] as String,
        shift: json['shift'] as String?,
        subject: json['subject'] as String,
        topic: json['topic'] as String,
        subtopic: json['subtopic'] as String?,
        questionType: QuestionType.values.firstWhere(
          (e) => e.name == json['questionType'],
          orElse: () => QuestionType.mcq,
        ),
        originalQuestion: json['originalQuestion'] as String,
        options: (json['options'] as List<dynamic>?)
                ?.map((e) => Option.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        officialAnswer: Answer.fromJson(
            json['officialAnswer'] as Map<String, dynamic>),
        garudaExplanation: json['garudaExplanation'] as String? ?? '',
        difficulty: json['difficulty'] as String? ?? 'Medium',
        language: json['language'] as String? ?? 'en',
        version: (json['version'] as num?)?.toInt() ?? 1,
        marks: (json['marks'] as num?)?.toDouble() ?? 2.0,
        negativeMarks: (json['negativeMarks'] as num?)?.toDouble() ?? 0.66,
        source: QuestionSource.fromJson(
            json['source'] as Map<String, dynamic>),
        verificationStatus:
            json['verificationStatus'] as String? ?? 'Verified',
        editorialStatus: EditorialStatus.values.firstWhere(
          (e) => e.name == json['editorialStatus'],
          orElse: () => EditorialStatus.readyForPublication,
        ),
        editorialReviews: (json['editorialReviews'] as List<dynamic>?)
                ?.map((e) => EditorialReview.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        analytics: json['analytics'] != null
            ? QuestionAnalytics.fromJson(
                json['analytics'] as Map<String, dynamic>)
            : const QuestionAnalytics(),
        conceptsTested: List<String>.from(json['conceptsTested'] ?? []),
        cognitiveLevel: CognitiveLevel.values.firstWhere(
          (e) => e.name == json['cognitiveLevel'],
          orElse: () => CognitiveLevel.understand,
        ),
        questionNature: QuestionNature.values.firstWhere(
          (e) => e.name == json['questionNature'],
          orElse: () => QuestionNature.conceptual,
        ),
        examWeight: (json['examWeight'] as num?)?.toDouble() ?? 1.0,
        frequency: (json['frequency'] as num?)?.toInt() ?? 1,
        trap: json['trap'] != null
            ? QuestionTrap.fromJson(json['trap'] as Map<String, dynamic>)
            : null,
        learningObjectives: json['learningObjectives'] != null
            ? LearningObjectives.fromJson(
                json['learningObjectives'] as Map<String, dynamic>)
            : null,
        microConcepts: List<String>.from(json['microConcepts'] ?? []),
        coreConcepts: List<String>.from(json['coreConcepts'] ?? []),
        knowledgeObjectLinks:
            List<String>.from(json['knowledgeObjectLinks'] ?? []),
        articleLinks: List<String>.from(json['articleLinks'] ?? []),
        actLinks: List<String>.from(json['actLinks'] ?? []),
        caseLinks: List<String>.from(json['caseLinks'] ?? []),
        amendmentLinks: List<String>.from(json['amendmentLinks'] ?? []),
        committeeLinks: List<String>.from(json['committeeLinks'] ?? []),
        reportLinks: List<String>.from(json['reportLinks'] ?? []),
        currentAffairsLinks:
            List<String>.from(json['currentAffairsLinks'] ?? []),
        relatedQuestionIds:
            List<String>.from(json['relatedQuestionIds'] ?? []),
        tags: List<String>.from(json['tags'] ?? []),
      );

  Question copyWith({
    String? id,
    int? questionNumber,
    String? examId,
    int? year,
    String? stage,
    String? paper,
    String? shift,
    String? subject,
    String? topic,
    String? subtopic,
    QuestionType? questionType,
    String? originalQuestion,
    List<Option>? options,
    Answer? officialAnswer,
    String? garudaExplanation,
    String? difficulty,
    String? language,
    int? version,
    double? marks,
    double? negativeMarks,
    QuestionSource? source,
    String? verificationStatus,
    EditorialStatus? editorialStatus,
    List<EditorialReview>? editorialReviews,
    QuestionAnalytics? analytics,
    List<String>? conceptsTested,
    CognitiveLevel? cognitiveLevel,
    QuestionNature? questionNature,
    double? examWeight,
    int? frequency,
    QuestionTrap? trap,
    LearningObjectives? learningObjectives,
    List<String>? microConcepts,
    List<String>? coreConcepts,
    List<String>? knowledgeObjectLinks,
    List<String>? articleLinks,
    List<String>? actLinks,
    List<String>? caseLinks,
    List<String>? amendmentLinks,
    List<String>? committeeLinks,
    List<String>? reportLinks,
    List<String>? currentAffairsLinks,
    List<String>? relatedQuestionIds,
    List<String>? tags,
  }) {
    return Question(
      id: id ?? this.id,
      questionNumber: questionNumber ?? this.questionNumber,
      examId: examId ?? this.examId,
      year: year ?? this.year,
      stage: stage ?? this.stage,
      paper: paper ?? this.paper,
      shift: shift ?? this.shift,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      questionType: questionType ?? this.questionType,
      originalQuestion: originalQuestion ?? this.originalQuestion,
      options: options ?? this.options,
      officialAnswer: officialAnswer ?? this.officialAnswer,
      garudaExplanation: garudaExplanation ?? this.garudaExplanation,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      version: version ?? this.version,
      marks: marks ?? this.marks,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      source: source ?? this.source,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      editorialReviews: editorialReviews ?? this.editorialReviews,
      analytics: analytics ?? this.analytics,
      conceptsTested: conceptsTested ?? this.conceptsTested,
      cognitiveLevel: cognitiveLevel ?? this.cognitiveLevel,
      questionNature: questionNature ?? this.questionNature,
      examWeight: examWeight ?? this.examWeight,
      frequency: frequency ?? this.frequency,
      trap: trap ?? this.trap,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      microConcepts: microConcepts ?? this.microConcepts,
      coreConcepts: coreConcepts ?? this.coreConcepts,
      knowledgeObjectLinks: knowledgeObjectLinks ?? this.knowledgeObjectLinks,
      articleLinks: articleLinks ?? this.articleLinks,
      actLinks: actLinks ?? this.actLinks,
      caseLinks: caseLinks ?? this.caseLinks,
      amendmentLinks: amendmentLinks ?? this.amendmentLinks,
      committeeLinks: committeeLinks ?? this.committeeLinks,
      reportLinks: reportLinks ?? this.reportLinks,
      currentAffairsLinks: currentAffairsLinks ?? this.currentAffairsLinks,
      relatedQuestionIds: relatedQuestionIds ?? this.relatedQuestionIds,
      tags: tags ?? this.tags,
    );
  }
}
