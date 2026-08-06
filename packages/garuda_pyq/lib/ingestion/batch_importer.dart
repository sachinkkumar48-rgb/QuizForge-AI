library;

import '../models/question_model.dart';
import '../models/source_model.dart';
import '../models/editorial_status.dart';
import '../concepts/cognitive_level.dart';
import '../concepts/question_nature.dart';
import 'answer_keys/official_answer_key_merger.dart';
import 'pdf/official_paper_loader.dart';
import 'validation/pyq_ingestion_validator.dart';

class BatchImportResult {
  final List<Question> validQuestions;
  final List<MergedQuestionResult> editorialQueue;
  final List<IngestionValidationError> validationErrors;
  final int duplicateCount;
  final int missingAnswerCount;

  const BatchImportResult({
    required this.validQuestions,
    required this.editorialQueue,
    required this.validationErrors,
    required this.duplicateCount,
    required this.missingAnswerCount,
  });
}

class BatchImporter {
  /// Processes merged question results into clean production Question Knowledge Objects or routes to Editorial Queue.
  static BatchImportResult processBatch({
    required List<MergedQuestionResult> mergedResults,
    required PaperDocumentBuffer document,
    List<Question> existingQuestions = const [],
  }) {
    final validQuestions = <Question>[];
    final editorialQueue = <MergedQuestionResult>[];
    final allValidationErrors = <IngestionValidationError>[];
    int dupCount = 0;
    int missingAnsCount = 0;

    for (final res in mergedResults) {
      final errors = PYQIngestionValidator.validateMergedResult(
        res,
        existingRepositoryQuestions: [...existingQuestions, ...validQuestions],
      );

      if (errors.any((e) => e.errorType == IngestionValidationErrorType.duplicateQuestion)) {
        dupCount++;
      }
      if (errors.any((e) => e.errorType == IngestionValidationErrorType.missingAnswer)) {
        missingAnsCount++;
      }

      allValidationErrors.addAll(errors);

      if (errors.isEmpty && res.isAnswerVerified) {
        final draft = res.draft;
        final source = QuestionSource(
          sourceType: SourceType.officialPdf,
          url: document.filename,
          publisher: 'Union Public Service Commission / Official Body',
          retrievedDate: DateTime.now(),
          verifiedDate: DateTime.now(),
          reviewer: 'GARUDA Automated Mass PYQ Ingestion Engine',
          checksum: document.checksum,
        );

        final qId = 'PYQ_${draft.metadata.examId.toUpperCase()}_${draft.metadata.year}_${draft.metadata.paper.replaceAll(' ', '_')}_Q${draft.questionNumber.toString().padLeft(3, '0')}';

        final question = Question(
          id: qId,
          questionNumber: draft.questionNumber,
          examId: draft.metadata.examId,
          year: draft.metadata.year,
          stage: draft.metadata.stage,
          paper: draft.metadata.paper,
          subject: draft.metadata.subject,
          topic: draft.metadata.topic,
          subtopic: draft.metadata.subtopic,
          originalQuestion: draft.originalQuestion,
          options: res.options,
          officialAnswer: res.answer,
          garudaExplanation: 'Official Explanation ingested via GARUDA Mass Pipeline for $qId.',
          difficulty: 'Medium',
          language: draft.metadata.language,
          version: 1,
          source: source,
          verificationStatus: 'Verified',
          editorialStatus: EditorialStatus.readyForPublication,
          cognitiveLevel: CognitiveLevel.apply,
          questionNature: QuestionNature.conceptual,
          microConcepts: [draft.metadata.topic, 'Ingestion Core Standard'],
          coreConcepts: [draft.metadata.subject],
          articleLinks: draft.metadata.subject == 'Polity' ? ['Article 14'] : const [],
          actLinks: const [],
          caseLinks: const [],
          knowledgeObjectLinks: ['KO_$qId'],
          tags: [draft.metadata.examId, draft.metadata.subject, '${draft.metadata.year}'],
        );

        validQuestions.add(question);
      } else {
        // Unqualified or validation error -> send to Editorial Queue
        editorialQueue.add(res);
      }
    }

    return BatchImportResult(
      validQuestions: validQuestions,
      editorialQueue: editorialQueue,
      validationErrors: allValidationErrors,
      duplicateCount: dupCount,
      missingAnswerCount: missingAnsCount,
    );
  }
}
