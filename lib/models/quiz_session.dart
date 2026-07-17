import 'quiz_model.dart';

class QuizSession {
  final String sessionId;
  final String sourceName;
  final DateTime createdAt;
  final DateTime lastSavedAt;
  final int totalQuestions;
  final int currentQuestionIndex;
  final Duration remainingTime;
  final Map<int, String?> selectedAnswers;
  final Map<int, QuestionStatus> questionStatuses;
  final List<QuizQuestion> quizQuestions;
  final int schemaVersion;

  const QuizSession({
    required this.sessionId,
    required this.sourceName,
    required this.createdAt,
    required this.lastSavedAt,
    required this.totalQuestions,
    required this.currentQuestionIndex,
    required this.remainingTime,
    required this.selectedAnswers,
    required this.questionStatuses,
    required this.quizQuestions,
    this.schemaVersion = 1,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    final Map<int, String?> answers = {};
    if (json['selectedAnswers'] != null) {
      (json['selectedAnswers'] as Map<String, dynamic>).forEach((k, v) {
        answers[int.parse(k)] = v as String?;
      });
    }

    final Map<int, QuestionStatus> statuses = {};
    if (json['questionStatuses'] != null) {
      (json['questionStatuses'] as Map<String, dynamic>).forEach((k, v) {
        statuses[int.parse(k)] = QuestionStatus.values.byName(v as String);
      });
    }

    return QuizSession(
      sessionId: json['sessionId'] as String,
      sourceName: json['sourceName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSavedAt: DateTime.parse(json['lastSavedAt'] as String),
      totalQuestions: json['totalQuestions'] as int,
      currentQuestionIndex: json['currentQuestionIndex'] as int,
      remainingTime: Duration(seconds: json['remainingTime'] as int),
      selectedAnswers: answers,
      questionStatuses: statuses,
      quizQuestions: (json['quizQuestions'] as List<dynamic>)
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'sourceName': sourceName,
      'createdAt': createdAt.toIso8601String(),
      'lastSavedAt': lastSavedAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'currentQuestionIndex': currentQuestionIndex,
      'remainingTime': remainingTime.inSeconds,
      'selectedAnswers':
          selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
      'questionStatuses':
          questionStatuses.map((k, v) => MapEntry(k.toString(), v.name)),
      'quizQuestions': quizQuestions.map((e) => e.toJson()).toList(),
      'schemaVersion': schemaVersion,
    };
  }

  QuizSession copyWith({
    String? sessionId,
    String? sourceName,
    DateTime? createdAt,
    DateTime? lastSavedAt,
    int? totalQuestions,
    int? currentQuestionIndex,
    Duration? remainingTime,
    Map<int, String?>? selectedAnswers,
    Map<int, QuestionStatus>? questionStatuses,
    List<QuizQuestion>? quizQuestions,
    int? schemaVersion,
  }) {
    return QuizSession(
      sessionId: sessionId ?? this.sessionId,
      sourceName: sourceName ?? this.sourceName,
      createdAt: createdAt ?? this.createdAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      questionStatuses: questionStatuses ?? this.questionStatuses,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
