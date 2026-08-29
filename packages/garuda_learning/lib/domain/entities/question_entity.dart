/// Generic Question Entity Interface & Metadata (TITAN-KO-026.0 Track 1).
///
/// Provides an exam-agnostic, provenance-preserving contract for questions
/// consumed by GARUDA Learning orchestration, evaluation, and diagnostic pipelines.
library;

import 'package:garuda_case_law/garuda_case_law.dart' show StructuredAnswer;
import 'package:meta/meta.dart';

/// Exam metadata associated with a question.
@immutable
class QuestionExamMetadata {
  final String examId;
  final int? year;
  final String? stage;
  final String? paper;
  final String? shift;
  final String? subject;
  final String? topic;
  final String? subtopic;

  const QuestionExamMetadata({
    required this.examId,
    this.year,
    this.stage,
    this.paper,
    this.shift,
    this.subject,
    this.topic,
    this.subtopic,
  });

  Map<String, dynamic> toJson() => {
        'examId': examId,
        if (year != null) 'year': year,
        if (stage != null) 'stage': stage,
        if (paper != null) 'paper': paper,
        if (shift != null) 'shift': shift,
        if (subject != null) 'subject': subject,
        if (topic != null) 'topic': topic,
        if (subtopic != null) 'subtopic': subtopic,
      };

  factory QuestionExamMetadata.fromJson(Map<String, dynamic> json) =>
      QuestionExamMetadata(
        examId: json['examId'] as String? ?? 'general',
        year: (json['year'] as num?)?.toInt(),
        stage: json['stage'] as String?,
        paper: json['paper'] as String?,
        shift: json['shift'] as String?,
        subject: json['subject'] as String?,
        topic: json['topic'] as String?,
        subtopic: json['subtopic'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionExamMetadata &&
          runtimeType == other.runtimeType &&
          examId == other.examId &&
          year == other.year &&
          paper == other.paper &&
          subject == other.subject &&
          topic == other.topic;

  @override
  int get hashCode => Object.hash(examId, year, paper, subject, topic);
}

/// Abstract contract for any question consumed by GARUDA Learning engines.
abstract interface class IQuestionEntity {
  /// Unique, stable, deterministic question identifier.
  String get id;

  /// The full question prompt/statement.
  String get prompt;

  /// Available options (for multiple-choice or structured response formats).
  List<String> get options;

  /// The expected correct answer representation.
  String get expectedAnswer;

  /// Optional educational explanation or rationale.
  String? get explanation;

  /// Verifiable educational provenance (source citation, publication, checksum).
  String get provenance;

  /// Curriculum learning objective IDs directly mapped to this question.
  List<String> get objectiveIds;

  /// Optional examination metadata (exam, paper, year, subject, topic).
  QuestionExamMetadata? get examMetadata;

  // Compatibility aliases for legacy LegalQuestion consumers:
  String get questionId => id;
  String get questionText => prompt;
  StructuredAnswer get answer;
  String get framing;
  List<String> get sourceRefs;
}
