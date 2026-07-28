import 'package:meta/meta.dart';
import 'package:titan_question_bank/titan_question_bank.dart';

/// Bloom's Taxonomy cognitive levels for generated learning objectives.
enum BloomTaxonomyLevel {
  remember,
  understand,
  apply,
  analyze,
  evaluate,
  create,
}

/// 30-second, 5-minute, and detailed summary bundle.
@immutable
class SummaryBundle {
  final String summary30s;
  final String summary5m;
  final String detailedSummary;

  const SummaryBundle({
    required this.summary30s,
    required this.summary5m,
    required this.detailedSummary,
  });

  Map<String, dynamic> toJson() => {
        'summary30s': summary30s,
        'summary5m': summary5m,
        'detailedSummary': detailedSummary,
      };

  factory SummaryBundle.fromJson(Map<String, dynamic> json) => SummaryBundle(
        summary30s: json['summary30s'] as String? ?? '',
        summary5m: json['summary5m'] as String? ?? '',
        detailedSummary: json['detailedSummary'] as String? ?? '',
      );
}

/// Generated Flashcard with hints and revision metadata.
@immutable
class GeneratedFlashcard {
  final String id;
  final String sourceKnowledgeObjectId;
  final String front;
  final String back;
  final String hint;
  final String difficulty; // Easy, Medium, Hard
  final String revisionPriority; // High, Medium, Low
  final DateTime createdAt;

  GeneratedFlashcard({
    required this.id,
    required this.sourceKnowledgeObjectId,
    required this.front,
    required this.back,
    this.hint = '',
    this.difficulty = 'Medium',
    this.revisionPriority = 'Medium',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceKnowledgeObjectId': sourceKnowledgeObjectId,
        'front': front,
        'back': back,
        'hint': hint,
        'difficulty': difficulty,
        'revisionPriority': revisionPriority,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeneratedFlashcard.fromJson(Map<String, dynamic> json) =>
      GeneratedFlashcard(
        id: json['id'] as String,
        sourceKnowledgeObjectId: json['sourceKnowledgeObjectId'] as String,
        front: json['front'] as String,
        back: json['back'] as String,
        hint: json['hint'] as String? ?? '',
        difficulty: json['difficulty'] as String? ?? 'Medium',
        revisionPriority: json['revisionPriority'] as String? ?? 'Medium',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

/// Generated Revision Notes (One Page, Last Minute, Exam Notes).
@immutable
class GeneratedRevisionNotes {
  final String sourceKnowledgeObjectId;
  final String onePageNotes;
  final String lastMinuteNotes;
  final String examNotes;
  final List<String> quickRevisionChecklist;

  GeneratedRevisionNotes({
    required this.sourceKnowledgeObjectId,
    required this.onePageNotes,
    required this.lastMinuteNotes,
    required this.examNotes,
    List<String>? quickRevisionChecklist,
  }) : quickRevisionChecklist = List.unmodifiable(quickRevisionChecklist ?? []);

  Map<String, dynamic> toJson() => {
        'sourceKnowledgeObjectId': sourceKnowledgeObjectId,
        'onePageNotes': onePageNotes,
        'lastMinuteNotes': lastMinuteNotes,
        'examNotes': examNotes,
        'quickRevisionChecklist': quickRevisionChecklist,
      };

  factory GeneratedRevisionNotes.fromJson(Map<String, dynamic> json) =>
      GeneratedRevisionNotes(
        sourceKnowledgeObjectId: json['sourceKnowledgeObjectId'] as String,
        onePageNotes: json['onePageNotes'] as String? ?? '',
        lastMinuteNotes: json['lastMinuteNotes'] as String? ?? '',
        examNotes: json['examNotes'] as String? ?? '',
        quickRevisionChecklist:
            List<String>.from(json['quickRevisionChecklist'] as List? ?? []),
      );
}

/// Node representation within a Mind Map.
@immutable
class MindMapNode {
  final String id;
  final String label;
  final int level;
  final String? parentId;

  const MindMapNode({
    required this.id,
    required this.label,
    required this.level,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'level': level,
        'parentId': parentId,
      };

  factory MindMapNode.fromJson(Map<String, dynamic> json) => MindMapNode(
        id: json['id'] as String,
        label: json['label'] as String,
        level: json['level'] as int,
        parentId: json['parentId'] as String?,
      );
}

/// Mind Map Structure graph asset.
@immutable
class MindMapStructure {
  final String id;
  final String sourceKnowledgeObjectId;
  final String title;
  final MindMapNode rootNode;
  final List<MindMapNode> nodes;
  final List<String> branches;
  final Map<String, List<String>> dependencies;

  MindMapStructure({
    required this.id,
    required this.sourceKnowledgeObjectId,
    required this.title,
    required this.rootNode,
    required List<MindMapNode> nodes,
    required List<String> branches,
    Map<String, List<String>>? dependencies,
  })  : nodes = List.unmodifiable(nodes),
        branches = List.unmodifiable(branches),
        dependencies = Map.unmodifiable(dependencies ?? {});

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceKnowledgeObjectId': sourceKnowledgeObjectId,
        'title': title,
        'rootNode': rootNode.toJson(),
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'branches': branches,
        'dependencies': dependencies,
      };

  factory MindMapStructure.fromJson(Map<String, dynamic> json) =>
      MindMapStructure(
        id: json['id'] as String,
        sourceKnowledgeObjectId: json['sourceKnowledgeObjectId'] as String,
        title: json['title'] as String,
        rootNode: MindMapNode.fromJson(
            Map<String, dynamic>.from(json['rootNode'] as Map)),
        nodes: (json['nodes'] as List? ?? [])
            .map((n) =>
                MindMapNode.fromJson(Map<String, dynamic>.from(n as Map)))
            .toList(),
        branches: List<String>.from(json['branches'] as List? ?? []),
        dependencies:
            Map<String, List<String>>.from(json['dependencies'] as Map? ?? {}),
      );
}

/// Learning Objectives and Cognitive Metadata.
@immutable
class LearningObjectivesMetadata {
  final List<String> learningObjectives;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final List<BloomTaxonomyLevel> bloomTags;
  final double difficultyScore; // 0.0 to 10.0
  final int estimatedStudyTimeMinutes;

  LearningObjectivesMetadata({
    required List<String> learningObjectives,
    required List<String> prerequisites,
    required List<String> learningOutcomes,
    required List<BloomTaxonomyLevel> bloomTags,
    this.difficultyScore = 5.0,
    this.estimatedStudyTimeMinutes = 15,
  })  : learningObjectives = List.unmodifiable(learningObjectives),
        prerequisites = List.unmodifiable(prerequisites),
        learningOutcomes = List.unmodifiable(learningOutcomes),
        bloomTags = List.unmodifiable(bloomTags);

  Map<String, dynamic> toJson() => {
        'learningObjectives': learningObjectives,
        'prerequisites': prerequisites,
        'learningOutcomes': learningOutcomes,
        'bloomTags': bloomTags.map((b) => b.name).toList(),
        'difficultyScore': difficultyScore,
        'estimatedStudyTimeMinutes': estimatedStudyTimeMinutes,
      };

  factory LearningObjectivesMetadata.fromJson(Map<String, dynamic> json) =>
      LearningObjectivesMetadata(
        learningObjectives:
            List<String>.from(json['learningObjectives'] as List? ?? []),
        prerequisites: List<String>.from(json['prerequisites'] as List? ?? []),
        learningOutcomes:
            List<String>.from(json['learningOutcomes'] as List? ?? []),
        bloomTags: (json['bloomTags'] as List? ?? [])
            .map((b) => BloomTaxonomyLevel.values.firstWhere((e) => e.name == b,
                orElse: () => BloomTaxonomyLevel.understand))
            .toList(),
        difficultyScore: (json['difficultyScore'] as num?)?.toDouble() ?? 5.0,
        estimatedStudyTimeMinutes:
            json['estimatedStudyTimeMinutes'] as int? ?? 15,
      );
}

/// AI Tutor Context asset.
@immutable
class AITutorContextAsset {
  final String sourceKnowledgeObjectId;
  final String contextPrompt;
  final Map<String, String> faqs;
  final List<String> misconceptions;
  final List<String> analogies;
  final List<String> followUpQuestions;

  AITutorContextAsset({
    required this.sourceKnowledgeObjectId,
    required this.contextPrompt,
    required Map<String, String> faqs,
    required List<String> misconceptions,
    required List<String> analogies,
    required List<String> followUpQuestions,
  })  : faqs = Map.unmodifiable(faqs),
        misconceptions = List.unmodifiable(misconceptions),
        analogies = List.unmodifiable(analogies),
        followUpQuestions = List.unmodifiable(followUpQuestions);

  Map<String, dynamic> toJson() => {
        'sourceKnowledgeObjectId': sourceKnowledgeObjectId,
        'contextPrompt': contextPrompt,
        'faqs': faqs,
        'misconceptions': misconceptions,
        'analogies': analogies,
        'followUpQuestions': followUpQuestions,
      };

  factory AITutorContextAsset.fromJson(Map<String, dynamic> json) =>
      AITutorContextAsset(
        sourceKnowledgeObjectId: json['sourceKnowledgeObjectId'] as String,
        contextPrompt: json['contextPrompt'] as String? ?? '',
        faqs: Map<String, String>.from(json['faqs'] as Map? ?? {}),
        misconceptions:
            List<String>.from(json['misconceptions'] as List? ?? []),
        analogies: List<String>.from(json['analogies'] as List? ?? []),
        followUpQuestions:
            List<String>.from(json['followUpQuestions'] as List? ?? []),
      );
}

/// Evaluation score produced by Knowledge Quality Engine.
@immutable
class KnowledgeQualityReport {
  final String sourceKnowledgeObjectId;
  final double score; // 0.0 to 100.0
  final double completenessScore;
  final double structureScore;
  final double readabilityScore;
  final double metadataScore;
  final double confidenceScore;
  final List<String> qualityIssues;

  KnowledgeQualityReport({
    required this.sourceKnowledgeObjectId,
    required this.score,
    required this.completenessScore,
    required this.structureScore,
    required this.readabilityScore,
    required this.metadataScore,
    required this.confidenceScore,
    List<String>? qualityIssues,
  }) : qualityIssues = List.unmodifiable(qualityIssues ?? []);

  Map<String, dynamic> toJson() => {
        'sourceKnowledgeObjectId': sourceKnowledgeObjectId,
        'score': score,
        'completenessScore': completenessScore,
        'structureScore': structureScore,
        'readabilityScore': readabilityScore,
        'metadataScore': metadataScore,
        'confidenceScore': confidenceScore,
        'qualityIssues': qualityIssues,
      };

  factory KnowledgeQualityReport.fromJson(Map<String, dynamic> json) =>
      KnowledgeQualityReport(
        sourceKnowledgeObjectId: json['sourceKnowledgeObjectId'] as String,
        score: (json['score'] as num?)?.toDouble() ?? 80.0,
        completenessScore:
            (json['completenessScore'] as num?)?.toDouble() ?? 80.0,
        structureScore: (json['structureScore'] as num?)?.toDouble() ?? 80.0,
        readabilityScore:
            (json['readabilityScore'] as num?)?.toDouble() ?? 80.0,
        metadataScore: (json['metadataScore'] as num?)?.toDouble() ?? 80.0,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 90.0,
        qualityIssues: List<String>.from(json['qualityIssues'] as List? ?? []),
      );
}

/// Master Container wrapping all generated educational assets for a KnowledgeObject.
@immutable
class GeneratedKnowledgeAssets {
  final String id;
  final String sourceKnowledgeObjectId;
  final String lessonTitle;
  final SummaryBundle summaries;
  final List<KmpQuestionItem> questions;
  final List<GeneratedFlashcard> flashcards;
  final GeneratedRevisionNotes revisionNotes;
  final MindMapStructure mindMap;
  final LearningObjectivesMetadata objectivesMetadata;
  final AITutorContextAsset tutorContext;
  final KnowledgeQualityReport qualityReport;
  final Map<String, dynamic> generationMetadata;
  final DateTime generatedAt;

  GeneratedKnowledgeAssets({
    required this.id,
    required this.sourceKnowledgeObjectId,
    required this.lessonTitle,
    required this.summaries,
    required List<KmpQuestionItem> questions,
    required List<GeneratedFlashcard> flashcards,
    required this.revisionNotes,
    required this.mindMap,
    required this.objectivesMetadata,
    required this.tutorContext,
    required this.qualityReport,
    Map<String, dynamic>? generationMetadata,
    DateTime? generatedAt,
  })  : questions = List.unmodifiable(questions),
        flashcards = List.unmodifiable(flashcards),
        generationMetadata = Map.unmodifiable(generationMetadata ?? {}),
        generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceKnowledgeObjectId': sourceKnowledgeObjectId,
        'lessonTitle': lessonTitle,
        'summaries': summaries.toJson(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'revisionNotes': revisionNotes.toJson(),
        'mindMap': mindMap.toJson(),
        'objectivesMetadata': objectivesMetadata.toJson(),
        'tutorContext': tutorContext.toJson(),
        'qualityReport': qualityReport.toJson(),
        'generationMetadata': generationMetadata,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory GeneratedKnowledgeAssets.fromJson(Map<String, dynamic> json) =>
      GeneratedKnowledgeAssets(
        id: json['id'] as String,
        sourceKnowledgeObjectId: json['sourceKnowledgeObjectId'] as String,
        lessonTitle: json['lessonTitle'] as String,
        summaries: SummaryBundle.fromJson(
            Map<String, dynamic>.from(json['summaries'] as Map)),
        questions: (json['questions'] as List? ?? [])
            .map((q) =>
                KmpQuestionItem.fromJson(Map<String, dynamic>.from(q as Map)))
            .toList(),
        flashcards: (json['flashcards'] as List? ?? [])
            .map((f) => GeneratedFlashcard.fromJson(
                Map<String, dynamic>.from(f as Map)))
            .toList(),
        revisionNotes: GeneratedRevisionNotes.fromJson(
            Map<String, dynamic>.from(json['revisionNotes'] as Map)),
        mindMap: MindMapStructure.fromJson(
            Map<String, dynamic>.from(json['mindMap'] as Map)),
        objectivesMetadata: LearningObjectivesMetadata.fromJson(
            Map<String, dynamic>.from(json['objectivesMetadata'] as Map)),
        tutorContext: AITutorContextAsset.fromJson(
            Map<String, dynamic>.from(json['tutorContext'] as Map)),
        qualityReport: KnowledgeQualityReport.fromJson(
            Map<String, dynamic>.from(json['qualityReport'] as Map)),
        generationMetadata:
            Map<String, dynamic>.from(json['generationMetadata'] as Map? ?? {}),
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : DateTime.now(),
      );
}
