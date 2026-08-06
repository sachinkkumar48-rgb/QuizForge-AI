library;

import '../../models/answer_model.dart';
import '../../models/option_model.dart';
import '../parser/option_extractor.dart';
import '../parser/official_paper_parser.dart';

class AnswerKeyEntry {
  final int questionNumber;
  final String correctOptionKey;
  final String source;
  final String version;

  const AnswerKeyEntry({
    required this.questionNumber,
    required this.correctOptionKey,
    this.source = 'Official Answer Key',
    this.version = 'v1.0',
  });
}

class MergedQuestionResult {
  final ParsedQuestionDraft draft;
  final List<Option> options;
  final Answer answer;
  final bool isAnswerVerified;
  final String? conflictWarning;

  const MergedQuestionResult({
    required this.draft,
    required this.options,
    required this.answer,
    required this.isAnswerVerified,
    this.conflictWarning,
  });
}

class OfficialAnswerKeyMerger {
  /// Merges a list of parsed question drafts with an official answer key map.
  static List<MergedQuestionResult> mergeAnswerKeys({
    required List<ParsedQuestionDraft> drafts,
    required Map<int, AnswerKeyEntry> answerKeyMap,
  }) {
    return drafts.map((draft) {
      final keyEntry = answerKeyMap[draft.questionNumber];
      final correctKey = keyEntry?.correctOptionKey.toUpperCase() ?? 'C';
      final isVerified = keyEntry != null;

      final options = OptionExtractor.extractOptions(
        draft.rawOptions,
        correctKey: correctKey,
      );

      final answer = Answer(
        correctOptionKeys: [correctKey],
        officialAnswerSource: keyEntry?.source ?? 'Pending Verification',
        verifiedDate: isVerified ? DateTime.now() : null,
      );

      return MergedQuestionResult(
        draft: draft,
        options: options,
        answer: answer,
        isAnswerVerified: isVerified,
        conflictWarning: keyEntry == null ? 'Missing official answer key entry for Question ${draft.questionNumber}' : null,
      );
    }).toList();
  }
}
