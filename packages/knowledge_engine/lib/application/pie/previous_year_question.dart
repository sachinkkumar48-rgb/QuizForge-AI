import 'package:meta/meta.dart';

/// Immutable domain entity representing a Previous Year Question (PYQ) payload in TITAN.
@immutable
class PreviousYearQuestion {
  /// Unique identifier of the question (e.g. 'pyq-cse-2023-q15').
  final String id;

  /// Full question prompt text.
  final String question;

  /// Multiple choice option strings (e.g. ['Option A', 'Option B', 'Option C', 'Option D']).
  final List<String> options;

  /// Correct answer key or option indicator (e.g. 'A', 'B', 'C', 'D' or option text).
  final String answer;

  /// Detailed solution or conceptual explanation.
  final String explanation;

  /// Examination name (e.g. 'UPSC CSE', 'NDA', 'CDS', 'CAPF').
  final String exam;

  /// Examination year (e.g. 2023).
  final int year;

  /// Paper identification (e.g. 'GS Paper I', 'CSAT', 'Paper II').
  final String paper;

  /// Broad subject category (e.g. 'Polity', 'History', 'Economy', 'Geography').
  final String subject;

  /// Specific syllabus topics (e.g. ['Preamble', 'Fundamental Rights']).
  final List<String> topics;

  /// Evaluated difficulty level ('Easy', 'Medium', 'Hard').
  final String difficulty;

  /// Associated indexing tags (e.g. ['PYQ 2023', 'Constitutional Law']).
  final List<String> tags;

  /// Constructs an immutable [PreviousYearQuestion].
  PreviousYearQuestion({
    required this.id,
    required this.question,
    List<String> options = const [],
    this.answer = '',
    this.explanation = '',
    this.exam = 'UPSC CSE',
    int? year,
    this.paper = 'GS Paper I',
    this.subject = 'General',
    List<String> topics = const [],
    this.difficulty = 'Medium',
    List<String> tags = const [],
  })  : year = year ?? DateTime.now().year,
        options = List<String>.unmodifiable(options),
        topics = List<String>.unmodifiable(topics),
        tags = List<String>.unmodifiable(tags);

  /// Creates a copy of this [PreviousYearQuestion] with updated fields.
  PreviousYearQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? answer,
    String? explanation,
    String? exam,
    int? year,
    String? paper,
    String? subject,
    List<String>? topics,
    String? difficulty,
    List<String>? tags,
  }) {
    return PreviousYearQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      exam: exam ?? this.exam,
      year: year ?? this.year,
      paper: paper ?? this.paper,
      subject: subject ?? this.subject,
      topics: topics ?? this.topics,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
    );
  }

  /// Converts this [PreviousYearQuestion] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'answer': answer,
      'explanation': explanation,
      'exam': exam,
      'year': year,
      'paper': paper,
      'subject': subject,
      'topics': topics,
      'difficulty': difficulty,
      'tags': tags,
    };
  }

  /// Deserializes a [PreviousYearQuestion] from a Map.
  factory PreviousYearQuestion.fromMap(Map<String, dynamic> map) {
    return PreviousYearQuestion(
      id: (map['id'] as String?) ?? '',
      question: (map['question'] as String?) ?? '',
      options: List<String>.from(map['options'] as List? ?? const []),
      answer: (map['answer'] as String?) ?? '',
      explanation: (map['explanation'] as String?) ?? '',
      exam: (map['exam'] as String?) ?? 'UPSC CSE',
      year: map['year'] != null
          ? (map['year'] as num).toInt()
          : DateTime.now().year,
      paper: (map['paper'] as String?) ?? 'GS Paper I',
      subject: (map['subject'] as String?) ?? 'General',
      topics: List<String>.from(map['topics'] as List? ?? const []),
      difficulty: (map['difficulty'] as String?) ?? 'Medium',
      tags: List<String>.from(map['tags'] as List? ?? const []),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PreviousYearQuestion &&
        other.id == id &&
        other.question == question &&
        _listEquals(other.options, options) &&
        other.answer == answer &&
        other.explanation == explanation &&
        other.exam == exam &&
        other.year == year &&
        other.paper == paper &&
        other.subject == subject &&
        _listEquals(other.topics, topics) &&
        other.difficulty == difficulty &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      question,
      Object.hashAll(options),
      answer,
      explanation,
      exam,
      year,
      paper,
      subject,
      Object.hashAll(topics),
      difficulty,
      Object.hashAll(tags),
    );
  }

  @override
  String toString() {
    return 'PreviousYearQuestion(id: $id, exam: $exam, year: $year, subject: $subject)';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
