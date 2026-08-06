library;

import '../pdf/official_paper_loader.dart';
import 'metadata_extractor.dart';
import 'question_extractor.dart';
import 'question_normalizer.dart';

class ParsedQuestionDraft {
  final int questionNumber;
  final String originalQuestion;
  final List<String> rawOptions;
  final ParsedMetadata metadata;

  const ParsedQuestionDraft({
    required this.questionNumber,
    required this.originalQuestion,
    required this.rawOptions,
    required this.metadata,
  });
}

class OfficialPaperParser {
  /// Parses PaperDocumentBuffer into a list of ParsedQuestionDraft.
  static List<ParsedQuestionDraft> parsePaper(PaperDocumentBuffer document) {
    final metadata = MetadataExtractor.extract(
      filename: document.filename,
      headerText: document.rawText,
      defaultMetadata: document.metadata,
    );

    final rawBlocks = QuestionExtractor.extractBlocks(document.rawText);

    return rawBlocks.map((block) {
      final normalizedText = QuestionNormalizer.normalizeText(block.questionText);
      return ParsedQuestionDraft(
        questionNumber: block.questionNumber,
        originalQuestion: normalizedText,
        rawOptions: block.rawOptions,
        metadata: metadata,
      );
    }).toList();
  }
}
