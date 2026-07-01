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