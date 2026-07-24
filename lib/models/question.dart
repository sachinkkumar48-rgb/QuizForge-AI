class Question {
  final String id;
  final String exam;
  final int year;
  final String paper;
  final String subject;
  final String topic;
  final String subtopic;
  final String difficulty;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  Question({
    required this.id,
    required this.exam,
    required this.year,
    required this.paper,
    required this.subject,
    required this.topic,
    this.subtopic = '',
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.tags = const [],
    this.metadata = const {},
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      exam: json['exam'] as String? ?? 'UPSC CSE Prelims',
      year: json['year'] as int? ?? 2024,
      paper: json['paper'] as String? ?? 'GS Paper 1',
      subject: json['subject'] as String? ?? 'General',
      topic: json['topic'] as String? ?? 'General',
      subtopic: json['subtopic'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      question: json['question'] as String? ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : const [],
      correctAnswer: json['correctAnswer'] as String? ?? '',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam': exam,
      'year': year,
      'paper': paper,
      'subject': subject,
      'topic': topic,
      'subtopic': subtopic,
      'difficulty': difficulty,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'tags': tags,
      'metadata': metadata,
    };
  }
}
