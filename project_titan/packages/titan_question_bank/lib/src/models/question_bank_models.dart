/// 8 supported Question Types in KMP Question Bank.
enum KmpQuestionType {
  mcq,
  pyq,
  subjective,
  assertionReason,
  matchTheFollowing,
  caseStudy,
  trueFalse,
  fillInBlanks;

  String get label {
    switch (this) {
      case KmpQuestionType.mcq:
        return 'Multiple Choice Question (MCQ)';
      case KmpQuestionType.pyq:
        return 'Previous Year Question (PYQ)';
      case KmpQuestionType.subjective:
        return 'Mains Subjective Essay';
      case KmpQuestionType.assertionReason:
        return 'Assertion–Reason';
      case KmpQuestionType.matchTheFollowing:
        return 'Match the Following';
      case KmpQuestionType.caseStudy:
        return 'Case Study';
      case KmpQuestionType.trueFalse:
        return 'True / False';
      case KmpQuestionType.fillInBlanks:
        return 'Fill in the Blanks';
    }
  }
}

/// Match pair representation for Match the Following items.
class MatchPair {
  final String left;
  final String right;

  const MatchPair({required this.left, required this.right});

  Map<String, dynamic> toJson() => {'left': left, 'right': right};
  factory MatchPair.fromJson(Map<String, dynamic> json) =>
      MatchPair(left: json['left'] as String, right: json['right'] as String);
}

/// Question Item Model supporting all 8 question types and solution rubrics.
class KmpQuestionItem {
  final String id;
  final String topicId;
  final String topicName;
  final KmpQuestionType type;
  final String stem;
  final List<String> options;
  final int correctAnswerIndex;
  final String solutionExplanation;
  final String assertionText;
  final String reasonText;
  final List<MatchPair> matchPairs;
  final String caseStudyContext;
  final int pyqYear;
  final String pyqExamName;
  final double positivePoints;
  final double negativePenalty;
  final String difficulty;
  final List<String> tags;
  final DateTime createdAt;

  const KmpQuestionItem({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.type,
    required this.stem,
    this.options = const [],
    this.correctAnswerIndex = 0,
    required this.solutionExplanation,
    this.assertionText = '',
    this.reasonText = '',
    this.matchPairs = const [],
    this.caseStudyContext = '',
    this.pyqYear = 0,
    this.pyqExamName = '',
    this.positivePoints = 2.0,
    this.negativePenalty = 0.66,
    this.difficulty = 'Medium',
    this.tags = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicId': topicId,
        'topicName': topicName,
        'type': type.name,
        'stem': stem,
        'options': options,
        'correctAnswerIndex': correctAnswerIndex,
        'solutionExplanation': solutionExplanation,
        'assertionText': assertionText,
        'reasonText': reasonText,
        'matchPairs': matchPairs.map((m) => m.toJson()).toList(),
        'caseStudyContext': caseStudyContext,
        'pyqYear': pyqYear,
        'pyqExamName': pyqExamName,
        'positivePoints': positivePoints,
        'negativePenalty': negativePenalty,
        'difficulty': difficulty,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KmpQuestionItem.fromJson(Map<String, dynamic> json) =>
      KmpQuestionItem(
        id: json['id'] as String,
        topicId: json['topicId'] as String? ?? '',
        topicName: json['topicName'] as String? ?? '',
        type: KmpQuestionType.values.firstWhere((e) => e.name == json['type'],
            orElse: () => KmpQuestionType.mcq),
        stem: json['stem'] as String,
        options: List<String>.from(json['options'] as List? ?? []),
        correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
        solutionExplanation: json['solutionExplanation'] as String? ?? '',
        assertionText: json['assertionText'] as String? ?? '',
        reasonText: json['reasonText'] as String? ?? '',
        matchPairs: (json['matchPairs'] as List? ?? [])
            .map((m) => MatchPair.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
        caseStudyContext: json['caseStudyContext'] as String? ?? '',
        pyqYear: json['pyqYear'] as int? ?? 0,
        pyqExamName: json['pyqExamName'] as String? ?? '',
        positivePoints: (json['positivePoints'] as num?)?.toDouble() ?? 2.0,
        negativePenalty: (json['negativePenalty'] as num?)?.toDouble() ?? 0.66,
        difficulty: json['difficulty'] as String? ?? 'Medium',
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}
