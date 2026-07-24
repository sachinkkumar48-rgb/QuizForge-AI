class PyqExplanation {
  final String official;
  final String? ai;
  final String? custom;
  final Map<String, String>? incorrectOptions;
  final List<String>? relatedConcepts;
  final String? previousYearTrend;

  PyqExplanation({
    required this.official,
    this.ai,
    this.custom,
    this.incorrectOptions,
    this.relatedConcepts,
    this.previousYearTrend,
  });

  factory PyqExplanation.fromJson(Map<String, dynamic> json) {
    Map<String, String>? optionsMap;
    if (json["incorrectOptions"] != null) {
      optionsMap = Map<String, String>.from(json["incorrectOptions"] as Map);
    }

    return PyqExplanation(
      official: json["official"] as String? ?? "",
      ai: json["ai"] as String?,
      custom: json["custom"] as String?,
      incorrectOptions: optionsMap,
      relatedConcepts: json["relatedConcepts"] != null
          ? List<String>.from(json["relatedConcepts"] as List)
          : null,
      previousYearTrend: json["previousYearTrend"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "official": official,
      if (ai != null) "ai": ai,
      if (custom != null) "custom": custom,
      if (incorrectOptions != null) "incorrectOptions": incorrectOptions,
      if (relatedConcepts != null) "relatedConcepts": relatedConcepts,
      if (previousYearTrend != null) "previousYearTrend": previousYearTrend,
    };
  }
}

class PyqQuestionModel {
  final String id;
  final int year;
  final String exam;
  final String paper;
  final String subject;
  final String topic;
  final String difficulty;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String officialAnswer;
  final PyqExplanation explanation;
  final String reference;
  final bool isBookmarked;
  final int timesAttempted;
  final int timesCorrect;
  final DateTime? lastAttempted;
  final List<String> tags;
  final String? userSelectedAnswer;

  PyqQuestionModel({
    required this.id,
    required this.year,
    required this.exam,
    required this.paper,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.officialAnswer,
    required this.explanation,
    required this.reference,
    this.isBookmarked = false,
    this.timesAttempted = 0,
    this.timesCorrect = 0,
    this.lastAttempted,
    this.tags = const [],
    this.userSelectedAnswer,
  });

  bool get isAttempted => timesAttempted > 0;
  bool get isLastAttemptCorrect =>
      userSelectedAnswer != null && userSelectedAnswer == correctAnswer;
  double get accuracy =>
      timesAttempted == 0 ? 0.0 : (timesCorrect / timesAttempted) * 100;

  PyqQuestionModel copyWith({
    String? id,
    int? year,
    String? exam,
    String? paper,
    String? subject,
    String? topic,
    String? difficulty,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? officialAnswer,
    PyqExplanation? explanation,
    String? reference,
    bool? isBookmarked,
    int? timesAttempted,
    int? timesCorrect,
    DateTime? lastAttempted,
    List<String>? tags,
    String? userSelectedAnswer,
  }) {
    return PyqQuestionModel(
      id: id ?? this.id,
      year: year ?? this.year,
      exam: exam ?? this.exam,
      paper: paper ?? this.paper,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      officialAnswer: officialAnswer ?? this.officialAnswer,
      explanation: explanation ?? this.explanation,
      reference: reference ?? this.reference,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      timesAttempted: timesAttempted ?? this.timesAttempted,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      lastAttempted: lastAttempted ?? this.lastAttempted,
      tags: tags ?? this.tags,
      userSelectedAnswer: userSelectedAnswer ?? this.userSelectedAnswer,
    );
  }

  factory PyqQuestionModel.fromJson(Map<String, dynamic> json) {
    return PyqQuestionModel(
      id: json["id"] as String? ?? "",
      year: json["year"] as int? ?? 2024,
      exam: json["exam"] as String? ?? "UPSC CSE Prelims",
      paper: json["paper"] as String? ?? "GS Paper 1",
      subject: json["subject"] as String? ?? "General",
      topic: json["topic"] as String? ?? "General",
      difficulty: json["difficulty"] as String? ?? "Medium",
      question: json["question"] as String? ?? "",
      options: json["options"] != null
          ? List<String>.from(json["options"] as List)
          : [],
      correctAnswer: json["correctAnswer"] as String? ?? "",
      officialAnswer: json["officialAnswer"] as String? ?? "A",
      explanation: json["explanation"] != null
          ? PyqExplanation.fromJson(json["explanation"] as Map<String, dynamic>)
          : PyqExplanation(official: ""),
      reference: json["reference"] as String? ?? "",
      isBookmarked: json["isBookmarked"] as bool? ?? false,
      timesAttempted: json["timesAttempted"] as int? ?? 0,
      timesCorrect: json["timesCorrect"] as int? ?? 0,
      lastAttempted: json["lastAttempted"] != null
          ? DateTime.tryParse(json["lastAttempted"] as String)
          : null,
      tags: json["tags"] != null
          ? List<String>.from(json["tags"] as List)
          : const [],
      userSelectedAnswer: json["userSelectedAnswer"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "year": year,
      "exam": exam,
      "paper": paper,
      "subject": subject,
      "topic": topic,
      "difficulty": difficulty,
      "question": question,
      "options": options,
      "correctAnswer": correctAnswer,
      "officialAnswer": officialAnswer,
      "explanation": explanation.toJson(),
      "reference": reference,
      "isBookmarked": isBookmarked,
      "timesAttempted": timesAttempted,
      "timesCorrect": timesCorrect,
      if (lastAttempted != null)
        "lastAttempted": lastAttempted!.toIso8601String(),
      "tags": tags,
      if (userSelectedAnswer != null) "userSelectedAnswer": userSelectedAnswer,
    };
  }
}
