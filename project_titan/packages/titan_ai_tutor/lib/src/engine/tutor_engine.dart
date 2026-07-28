import '../models/tutor_models.dart';

/// Pure Dart adaptive teaching engine for Project TITAN.
///
/// Handles adaptive teaching, misconception detection, Socratic questioning,
/// personalized explanations, dynamic difficulty tuning, learning objective tracking,
/// concept reinforcement, prerequisite validation, confidence, and mastery estimation.
class TutorEngine {
  const TutorEngine();

  /// Generates a structured lesson tailored to the concept, persona, and difficulty level.
  TutorLesson explainConcept({
    required TutorConcept concept,
    required TutorPersona persona,
    TutorDifficultyLevel difficulty = TutorDifficultyLevel.intermediate,
  }) {
    final explanation = _buildExplanation(concept, persona);
    final analogy = _buildAnalogy(concept, persona);
    final mnemonic = _buildMnemonic(concept, persona);
    final examples = _buildExamples(concept, persona);

    return TutorLesson(
      id: 'lesson_${concept.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Mastering ${concept.title} (${persona.displayName})',
      conceptId: concept.id,
      explanation: explanation,
      analogy: analogy,
      mnemonic: mnemonic,
      examples: examples,
      difficulty: difficulty,
      estimatedDurationMinutes: persona == TutorPersona.eli5 ? 10 : 20,
      createdAt: DateTime.now(),
    );
  }

  /// Formulates a Socratic question to guide student reasoning.
  TutorQuestion generateSocraticQuestion({
    required TutorConcept concept,
    TutorDifficultyLevel difficulty = TutorDifficultyLevel.intermediate,
  }) {
    return TutorQuestion(
      id: 'soc_${concept.id}_${DateTime.now().millisecondsSinceEpoch}',
      conceptId: concept.id,
      questionText:
          'Consider the core principle of ${concept.title}. Why is this foundational to understanding modern ${concept.subjectCategory}?',
      type: TutorQuestionType.socratic,
      correctAnswer:
          'Key principle connects cause, mechanism, and real-world outcomes.',
      explanation:
          'Socratic questioning prompts critical evaluation of underlying assumptions.',
      difficulty: difficulty,
    );
  }

  /// Detects potential misconceptions from student responses.
  List<String> detectMisconceptions({
    required String studentResponse,
    required TutorConcept concept,
  }) {
    final misconceptions = <String>[];
    final lower = studentResponse.toLowerCase();

    if (lower.contains('always') || lower.contains('never')) {
      misconceptions.add(
          'Absolutist assumption: Overgeneralization of exceptions in ${concept.title}');
    }
    if (lower.contains('confuse') || lower.contains('same as')) {
      misconceptions.add(
          'Conceptual confusion between ${concept.title} and related topics.');
    }
    if (studentResponse.trim().length < 10) {
      misconceptions
          .add('Incomplete reasoning: Missing causal steps in explanation.');
    }

    return misconceptions;
  }

  /// Evaluates a student answer and returns a [TutorEvaluation].
  TutorEvaluation evaluateAnswer({
    required TutorExercise exercise,
    required String studentResponse,
    required TutorConcept concept,
  }) {
    final misconceptions = detectMisconceptions(
      studentResponse: studentResponse,
      concept: concept,
    );

    double score = 85.0;
    if (misconceptions.isNotEmpty) {
      score -= misconceptions.length * 15.0;
      if (score < 0.0) score = 0.0;
    }

    EvaluationGrade grade;
    if (score >= 90) {
      grade = EvaluationGrade.mastered;
    } else if (score >= 75) {
      grade = EvaluationGrade.excellent;
    } else if (score >= 60) {
      grade = EvaluationGrade.good;
    } else if (score >= 40) {
      grade = EvaluationGrade.satisfactory;
    } else {
      grade = EvaluationGrade.needsImprovement;
    }

    return TutorEvaluation(
      id: 'eval_${exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
      targetId: exercise.id,
      score: score,
      grade: grade,
      feedbackText: score >= 70
          ? 'Great job! You showed solid understanding of ${concept.title}.'
          : 'Good effort. Let us reinforce key nuances in ${concept.title}.',
      masteredConcepts: score >= 70 ? [concept.id] : [],
      weakAreas: score < 70 ? [concept.id] : [],
      detectedMisconceptions: misconceptions,
      recommendations: [
        if (misconceptions.isNotEmpty)
          'Review mnemonic and analogies for ${concept.title}',
        'Practice 2 more revision questions on ${concept.title}',
      ],
      evaluatedAt: DateTime.now(),
    );
  }

  /// Adjusts difficulty dynamically based on performance trend.
  TutorDifficulty adjustDifficulty({
    required TutorDifficulty current,
    required double lastScore,
    required int consecutiveSuccesses,
  }) {
    double scale = current.numericScale;
    TutorDifficultyLevel level = current.currentLevel;
    String reason = 'Maintained current difficulty';

    if (lastScore >= 85.0 && consecutiveSuccesses >= 2) {
      scale = (scale + 1.0).clamp(1.0, 10.0);
      reason = 'Increased difficulty due to high performance streak';
      if (scale >= 8.5) {
        level = TutorDifficultyLevel.expert;
      } else if (scale >= 6.5) {
        level = TutorDifficultyLevel.advanced;
      } else if (scale >= 4.0) {
        level = TutorDifficultyLevel.intermediate;
      }
    } else if (lastScore < 50.0) {
      scale = (scale - 1.0).clamp(1.0, 10.0);
      reason = 'Scaffolded difficulty to rebuild baseline understanding';
      if (scale < 3.5) {
        level = TutorDifficultyLevel.beginner;
      } else if (scale < 6.5) {
        level = TutorDifficultyLevel.intermediate;
      }
    }

    return TutorDifficulty(
      currentLevel: level,
      numericScale: scale,
      dynamicAdjustmentFactor: scale / 5.0,
      adaptReason: reason,
    );
  }

  /// Estimates updated mastery score using exponentially weighted moving average.
  double estimateMastery({
    required double currentMastery,
    required double newScore,
  }) {
    final updated = (currentMastery * 0.7) + (newScore * 0.3);
    return updated.clamp(0.0, 100.0);
  }

  /// Estimates learner confidence score (0.0 to 1.0).
  double estimateConfidence({
    required int hintsUsed,
    required double score,
    required int responseTimeSeconds,
  }) {
    double conf = (score / 100.0) - (hintsUsed * 0.15);
    if (responseTimeSeconds > 120) {
      conf -= 0.1;
    }
    return conf.clamp(0.0, 1.0);
  }

  /// Validates prerequisites and returns missing concept IDs.
  List<String> checkPrerequisites({
    required TutorConcept concept,
    required Map<String, double> userMasteries,
    double requiredThreshold = 60.0,
  }) {
    final missing = <String>[];
    for (final prereqId in concept.prerequisiteConceptIds) {
      final score = userMasteries[prereqId] ?? 0.0;
      if (score < requiredThreshold) {
        missing.add(prereqId);
      }
    }
    return missing;
  }

  /// Generates a reinforcement practice exercise targeting weak points.
  TutorExercise generateReinforcementDrill({
    required TutorConcept concept,
    required TutorMemory memory,
  }) {
    return TutorExercise(
      id: 'ex_${concept.id}_${DateTime.now().millisecondsSinceEpoch}',
      conceptId: concept.id,
      title: 'Reinforcement Drill: ${concept.title}',
      prompt:
          'Address prior misconception: ${memory.rememberedMisconceptions.isNotEmpty ? memory.rememberedMisconceptions.first : "Explain ${concept.title} step-by-step."}',
      type: TutorQuestionType.openEnded,
      status: TutorExerciseStatus.pending,
    );
  }

  /// Generates an assignment with structured exercises.
  List<TutorExercise> generateAssignment({
    required TutorConcept concept,
    required TutorPersona persona,
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => TutorExercise(
        id: 'asgn_${concept.id}_${index + 1}_${DateTime.now().millisecondsSinceEpoch}',
        conceptId: concept.id,
        title: 'Assignment Q${index + 1}: ${concept.title}',
        prompt:
            '${persona.displayName} Challenge: Explain how ${concept.title} applies to practical scenarios.',
        type: index % 2 == 0
            ? TutorQuestionType.multipleChoice
            : TutorQuestionType.openEnded,
        status: TutorExerciseStatus.pending,
      ),
    );
  }

  // --- Internal Helper Generators ---

  String _buildExplanation(TutorConcept concept, TutorPersona persona) {
    switch (persona) {
      case TutorPersona.eli5:
        return 'Imagine ${concept.title} like a game where every rule helps keep things fair and balanced!';
      case TutorPersona.beginner:
        return '${concept.title} is a foundational topic in ${concept.subjectCategory}. Let us break down its core elements step by step: ${concept.description}';
      case TutorPersona.intermediate:
        return '${concept.title} connects key principles across ${concept.subjectCategory}. Core mechanism: ${concept.description}';
      case TutorPersona.advanced:
        return 'Advanced breakdown of ${concept.title}: Analyzing theoretical frameworks, institutional dynamics, and policy impacts. ${concept.description}';
      case TutorPersona.upscMode:
        return '[UPSC Mains & Prelims Mode] ${concept.title}: Key constitutional/analytical provisions, historical context, current significance, and critical evaluation points for GS papers.';
      case TutorPersona.interviewMode:
        return '[UPSC Personality Test Mode] If asked about ${concept.title} by the Board: State the core issue succinctly, present balanced perspectives, and suggest constructive solutions.';
    }
  }

  String _buildAnalogy(TutorConcept concept, TutorPersona persona) {
    return 'Analogy for ${concept.title}: Thinking of it as an interconnected network where altering one node affects the entire system.';
  }

  String _buildMnemonic(TutorConcept concept, TutorPersona persona) {
    final titleClean = concept.title.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    final firstChar = titleClean.isNotEmpty ? titleClean[0].toUpperCase() : 'C';
    return '$firstChar.A.R.E. (Concept, Application, Reasoning, Evaluation) for ${concept.title}';
  }

  List<String> _buildExamples(TutorConcept concept, TutorPersona persona) {
    return [
      'Example 1: Classic application of ${concept.title} in governance.',
      'Example 2: Recent Indian context case study involving ${concept.title}.',
    ];
  }
}
