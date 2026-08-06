import '../models/editorial_status.dart';
import '../models/question_model.dart';

class OCRPipeline {
  /// Processes OCR raw image result into structured Question draft.
  static Question processOcrResult(Question questionDraft, String ocrText) {
    return questionDraft.copyWith(
      originalQuestion: ocrText.trim(),
      editorialStatus: EditorialStatus.verificationPending,
      verificationStatus: 'Pending Verification',
    );
  }
}
