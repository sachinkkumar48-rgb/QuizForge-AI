import 'package:garuda_learning/garuda_learning.dart';
import 'package:test/test.dart';

void main() {
  group('SessionConfiguration Domain Model Tests (TITAN-KO-019.0 P19)', () {
    test('SessionConfiguration initializes cleanly with valid fields', () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_fr_art21', 'lo_fr_art14'],
        questionLimit: 15,
        selectionPolicy: QuestionSelectionPolicy.unattemptedOnly,
        sequencerPolicy: QuestionSequencerPolicy.difficultyAscending,
        allowRepeatAttempts: false,
      );

      expect(config.learnerId, 'learner_101');
      expect(config.objectiveIds, ['lo_fr_art21', 'lo_fr_art14']);
      expect(config.questionLimit, 15);
      expect(config.selectionPolicy, QuestionSelectionPolicy.unattemptedOnly);
      expect(
          config.sequencerPolicy, QuestionSequencerPolicy.difficultyAscending);
      expect(config.allowRepeatAttempts, false);
    });

    test('SessionConfiguration rejects empty learnerId or objectiveIds', () {
      expect(
        () => SessionConfiguration(
          learnerId: '',
          objectiveIds: ['lo_fr_art21'],
        ),
        throwsArgumentError,
      );

      expect(
        () => SessionConfiguration(
          learnerId: 'learner_101',
          objectiveIds: [],
        ),
        throwsArgumentError,
      );

      expect(
        () => SessionConfiguration(
          learnerId: 'learner_101',
          objectiveIds: ['lo_fr_art21', '   '],
        ),
        throwsArgumentError,
      );
    });

    test('SessionConfiguration rejects non-positive questionLimit', () {
      expect(
        () => SessionConfiguration(
          learnerId: 'learner_101',
          objectiveIds: ['lo_fr_art21'],
          questionLimit: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => SessionConfiguration(
          learnerId: 'learner_101',
          objectiveIds: ['lo_fr_art21'],
          questionLimit: -5,
        ),
        throwsArgumentError,
      );
    });

    test('SessionConfiguration serializes to and from JSON correctly', () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_fr_art21'],
        questionLimit: 10,
        selectionPolicy: QuestionSelectionPolicy.incorrectFocus,
        sequencerPolicy: QuestionSequencerPolicy.deterministicShuffle,
      );

      final json = config.toJson();
      final roundTrip = SessionConfiguration.fromJson(json);

      expect(roundTrip, config);
      expect(roundTrip.selectionPolicy, QuestionSelectionPolicy.incorrectFocus);
      expect(roundTrip.sequencerPolicy,
          QuestionSequencerPolicy.deterministicShuffle);
    });

    test('SessionProgressSummary calculates metrics correctly', () {
      const summary = SessionProgressSummary(
        sessionId: 'lsess_001',
        learnerId: 'learner_101',
        totalQuestions: 10,
        answeredCount: 5,
        correctCount: 4,
        currentScore: 0.80,
        state: LearningSessionState.active,
        isCompleted: false,
      );

      expect(summary.sessionId, 'lsess_001');
      expect(summary.totalQuestions, 10);
      expect(summary.answeredCount, 5);
      expect(summary.correctCount, 4);
      expect(summary.currentScore, 0.80);
      expect(summary.isCompleted, false);

      final json = summary.toJson();
      expect(SessionProgressSummary.fromJson(json), summary);
    });
  });
}
