/// Question Sequencer (TITAN-KO-019.0 P19).
///
/// Deterministic question sequencing engine ordering questions reproducibly.
library;

import 'package:garuda_case_law/garuda_case_law.dart' show LegalQuestion;

import '../domain/entities/question_sequencer_policy.dart';
import '../service/curriculum_service.dart';

class QuestionSequencer {
  final CurriculumService _curriculumService;

  QuestionSequencer({required CurriculumService curriculumService})
      : _curriculumService = curriculumService;

  /// Sequences the given [questions] deterministically according to [policy].
  List<LegalQuestion> sequenceQuestions({
    required List<LegalQuestion> questions,
    required List<String> objectiveIds,
    QuestionSequencerPolicy policy = QuestionSequencerPolicy.curriculumOrder,
    String? seed,
  }) {
    if (questions.isEmpty) return const [];

    final list = List<LegalQuestion>.from(questions);

    switch (policy) {
      case QuestionSequencerPolicy.curriculumOrder:
        list.sort((a, b) {
          final seqA = _getObjectiveSequenceIndex(a, objectiveIds);
          final seqB = _getObjectiveSequenceIndex(b, objectiveIds);
          final comp = seqA.compareTo(seqB);
          if (comp != 0) return comp;
          return a.questionId.compareTo(b.questionId);
        });
        break;

      case QuestionSequencerPolicy.difficultyAscending:
        list.sort((a, b) {
          final diffA = _getObjectiveBloomLevel(a, objectiveIds);
          final diffB = _getObjectiveBloomLevel(b, objectiveIds);
          final comp = diffA.compareTo(diffB);
          if (comp != 0) return comp;
          return a.questionId.compareTo(b.questionId);
        });
        break;

      case QuestionSequencerPolicy.deterministicShuffle:
        _deterministicShuffle(list, seed ?? objectiveIds.join('_'));
        break;

      case QuestionSequencerPolicy.sequential:
        list.sort((a, b) => a.questionId.compareTo(b.questionId));
        break;
    }

    return List.unmodifiable(list);
  }

  int _getObjectiveSequenceIndex(
      LegalQuestion question, List<String> objectiveIds) {
    for (final objId in objectiveIds) {
      final obj = _curriculumService.getObjectiveById(objId);
      if (obj != null) {
        return obj.sequenceIndex;
      }
    }
    return 0;
  }

  int _getObjectiveBloomLevel(
      LegalQuestion question, List<String> objectiveIds) {
    for (final objId in objectiveIds) {
      final obj = _curriculumService.getObjectiveById(objId);
      if (obj != null) {
        return obj.bloomLevel.index;
      }
    }
    return 0;
  }

  /// Reproducibly shuffles a list using a deterministic seed string.
  static void _deterministicShuffle<T>(List<T> list, String seedString) {
    if (list.length <= 1) return;

    var hash = 0;
    for (var i = 0; i < seedString.length; i++) {
      hash = (hash * 31 + seedString.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    // Pseudo-random generator with deterministic seed
    int nextRand() {
      hash = (hash * 1103515245 + 12345) & 0x7FFFFFFF;
      return hash;
    }

    for (var i = list.length - 1; i > 0; i--) {
      final j = nextRand() % (i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}
