/// Question Sequencer Policy Enum (TITAN-KO-019.0 P19).
///
/// Deterministic strategy for ordering selected P15 questions in a learning session.
library;

enum QuestionSequencerPolicy {
  /// Orders questions according to P17 curriculum hierarchy and sequence indices.
  curriculumOrder,

  /// Orders questions by Bloom's taxonomy cognitive level ascending.
  difficultyAscending,

  /// Reproducibly shuffles questions using a deterministic seed (hash of session/learner ID).
  deterministicShuffle,

  /// Preserves natural question repository list order.
  sequential;

  String get displayName => switch (this) {
        QuestionSequencerPolicy.curriculumOrder => 'Curriculum Sequence Order',
        QuestionSequencerPolicy.difficultyAscending =>
          'Bloom Taxonomy Level (Ascending)',
        QuestionSequencerPolicy.deterministicShuffle => 'Deterministic Shuffle',
        QuestionSequencerPolicy.sequential => 'Sequential (Source Order)',
      };
}
