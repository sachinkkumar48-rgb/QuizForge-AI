import '../models/answer_model.dart';
import '../models/editorial_status.dart';
import '../models/option_model.dart';
import '../models/question_model.dart';
import '../models/source_model.dart';

class ManualEntryIngestion {
  /// Converts manual input fields into a validated Question domain model.
  static Question createQuestion({
    required String id,
    required String examId,
    required int year,
    required String stage,
    required String paper,
    String? shift,
    required String subject,
    required String topic,
    String? subtopic,
    required String originalQuestion,
    required List<Map<String, dynamic>> rawOptions,
    required List<String> correctKeys,
    required String garudaExplanation,
    String difficulty = 'Medium',
    String language = 'en',
    double marks = 2.0,
    double negativeMarks = 0.66,
    required String reviewerName,
    List<String> articleLinks = const [],
    List<String> caseLinks = const [],
    List<String> actLinks = const [],
    List<String> tags = const [],
  }) {
    final options = rawOptions
        .map((opt) => Option(
              key: opt['key'] as String,
              text: opt['text'] as String,
              explanation: opt['explanation'] as String?,
              isCorrect: correctKeys.contains(opt['key']),
            ))
        .toList();

    final source = QuestionSource(
      sourceType: SourceType.editorialEntry,
      publisher: 'GARUDA Manual Entry',
      retrievedDate: DateTime.now(),
      verifiedDate: DateTime.now(),
      reviewer: reviewerName,
      checksum: 'manual_${id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    return Question(
      id: id,
      examId: examId,
      year: year,
      stage: stage,
      paper: paper,
      shift: shift,
      subject: subject,
      topic: topic,
      subtopic: subtopic,
      originalQuestion: originalQuestion,
      options: options,
      officialAnswer: Answer(
        correctOptionKeys: correctKeys,
        officialAnswerSource: 'Manual Verified Key',
        verifiedDate: DateTime.now(),
      ),
      garudaExplanation: garudaExplanation,
      difficulty: difficulty,
      language: language,
      marks: marks,
      negativeMarks: negativeMarks,
      source: source,
      verificationStatus: 'Verified',
      editorialStatus: EditorialStatus.verified,
      articleLinks: articleLinks,
      caseLinks: caseLinks,
      actLinks: actLinks,
      tags: tags,
    );
  }
}
