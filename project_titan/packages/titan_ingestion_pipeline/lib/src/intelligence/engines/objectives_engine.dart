import '../../models/knowledge_object.dart';
import '../models/generated_learning_assets.dart';

/// Learning Objectives & Bloom's Taxonomy Engine.
class ObjectivesEngine {
  /// Generates [LearningObjectivesMetadata] from a [KnowledgeObject].
  LearningObjectivesMetadata generate(KnowledgeObject obj) {
    final title = obj.title;

    final objectives = obj.learningObjectives.isNotEmpty
        ? obj.learningObjectives
        : [
            'Understand the core principles of $title',
            'Analyze the legal and administrative framework of $title',
            'Apply concepts of $title to exam scenarios',
          ];

    final prerequisites = obj.prerequisites.isNotEmpty
        ? obj.prerequisites
        : [
            'Basic understanding of Indian Constitution & Polity',
            'Familiarity with general legal terminology',
          ];

    final outcomes = obj.learningOutcomes.isNotEmpty
        ? obj.learningOutcomes
        : [
            'Mastery over $title concepts & case laws',
            'Ability to solve MCQs and Mains essays on $title',
          ];

    final bloomTags = [
      BloomTaxonomyLevel.remember,
      BloomTaxonomyLevel.understand,
      BloomTaxonomyLevel.analyze,
      BloomTaxonomyLevel.evaluate,
    ];

    final difficultyScore = obj.difficulty == 'easy'
        ? 3.0
        : obj.difficulty == 'hard'
            ? 8.5
            : 5.5;

    final studyTime =
        obj.estimatedReadingTime > 0 ? obj.estimatedReadingTime : 20;

    return LearningObjectivesMetadata(
      learningObjectives: objectives,
      prerequisites: prerequisites,
      learningOutcomes: outcomes,
      bloomTags: bloomTags,
      difficultyScore: difficultyScore,
      estimatedStudyTimeMinutes: studyTime,
    );
  }
}
