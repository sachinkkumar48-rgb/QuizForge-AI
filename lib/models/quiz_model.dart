enum QuestionStatus {
  notVisited,
  visited,
  answered,
  markedForReview,
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;
  final String subject;
  final String difficulty;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.subject,
    required this.difficulty,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json["question"] ?? "",
      options: List<String>.from(json["options"] ?? []),
      answer: json["answer"] ?? "",
      explanation: json["explanation"] ?? "",
      subject: json["subject"] ?? "General",
      difficulty: json["difficulty"] ?? "Medium",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      "options": options,
      "answer": answer,
      "explanation": explanation,
      "subject": subject,
      "difficulty": difficulty,
    };
  }
}

class QuizModel {
  final List<QuizQuestion> questions;
  final String? id;
  final String? sourceName;
  final DateTime? createdAt;

  QuizModel({
    required this.questions,
    this.id,
    this.sourceName,
    this.createdAt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      questions: (json["questions"] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      id: json["id"] as String?,
      sourceName: json["sourceName"] as String?,
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "questions": questions.map((q) => q.toJson()).toList(),
      if (id != null) "id": id,
      if (sourceName != null) "sourceName": sourceName,
      if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
    };
  }
}
