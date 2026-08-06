library;

import '../models/exam_model.dart';
import '../models/question_model.dart';

enum ValidationErrorCode {
  duplicateQuestion,
  brokenLink,
  missingMetadata,
  invalidYear,
  invalidExam,
  invalidMapping,
  missingConcepts,
  missingEvidence,
  missingEditorialReview,
  unverifiedOfficialAnswer,
}

class ValidationError {
  final ValidationErrorCode code;
  final String message;
  final String questionId;

  const ValidationError({
    required this.code,
    required this.message,
    required this.questionId,
  });

  @override
  String toString() => '[$code] Question $questionId: $message';
}

class PYQValidator {
  static List<ValidationError> validateQuestion(
    Question question, {
    List<Question> existingQuestions = const [],
  }) {
    final errors = <ValidationError>[];

    // 1. Invalid Exam
    final validExams = SupportedExam.initialExams.map((e) => e.id.toLowerCase()).toSet();
    if (question.examId.trim().isEmpty ||
        (!validExams.contains(question.examId.toLowerCase()) &&
            !question.examId.startsWith('custom_'))) {
      errors.add(ValidationError(
        code: ValidationErrorCode.invalidExam,
        message: 'Invalid or unsupported Exam ID: ${question.examId}',
        questionId: question.id,
      ));
    }

    // 2. Invalid Year
    final currentYear = DateTime.now().year + 1;
    if (question.year < 1950 || question.year > currentYear) {
      errors.add(ValidationError(
        code: ValidationErrorCode.invalidYear,
        message: 'Invalid examination year: ${question.year}',
        questionId: question.id,
      ));
    }

    // 3. Missing Metadata
    if (question.id.trim().isEmpty ||
        question.subject.trim().isEmpty ||
        question.topic.trim().isEmpty ||
        question.originalQuestion.trim().isEmpty) {
      errors.add(ValidationError(
        code: ValidationErrorCode.missingMetadata,
        message: 'Question missing mandatory metadata (ID, subject, topic, or question text)',
        questionId: question.id,
      ));
    }

    // 4. Official Answer Verification
    if (question.officialAnswer.correctOptionKeys.isEmpty ||
        question.officialAnswer.officialAnswerSource.trim().isEmpty) {
      errors.add(ValidationError(
        code: ValidationErrorCode.unverifiedOfficialAnswer,
        message: 'Question lacks verified official answer key or source',
        questionId: question.id,
      ));
    }

    // 5. Missing Concepts Check
    if (question.conceptsTested.isEmpty && question.microConcepts.isEmpty) {
      errors.add(ValidationError(
        code: ValidationErrorCode.missingConcepts,
        message: 'Question lacks mapped concepts or micro concepts',
        questionId: question.id,
      ));
    }

    // 6. Missing Evidence Check
    final urlEmpty = question.source.url?.trim().isEmpty ?? true;
    if (question.source.checksum.trim().isEmpty || urlEmpty) {
      errors.add(ValidationError(
        code: ValidationErrorCode.missingEvidence,
        message: 'Question source missing URL or checksum verification',
        questionId: question.id,
      ));
    }

    // 7. Broken Links Check
    for (final link in question.knowledgeObjectLinks) {
      if (link.trim().isEmpty || link.contains(' ')) {
        errors.add(ValidationError(
          code: ValidationErrorCode.brokenLink,
          message: 'Malformed or broken Knowledge Link: $link',
          questionId: question.id,
        ));
      }
    }

    // 8. Duplicate Question Check
    for (final existing in existingQuestions) {
      if (existing.id != question.id &&
          existing.originalQuestion.trim().toLowerCase() ==
              question.originalQuestion.trim().toLowerCase() &&
          existing.examId == question.examId &&
          existing.year == question.year) {
        errors.add(ValidationError(
          code: ValidationErrorCode.duplicateQuestion,
          message: 'Duplicate question text detected with existing question ${existing.id}',
          questionId: question.id,
        ));
      }
    }

    return errors;
  }

  static List<ValidationError> validateBatch(List<Question> questions) {
    final allErrors = <ValidationError>[];
    for (var i = 0; i < questions.length; i++) {
      final current = questions[i];
      final others = [...questions.sublist(0, i), ...questions.sublist(i + 1)];
      allErrors.addAll(validateQuestion(current, existingQuestions: others));
    }
    return allErrors;
  }
}
