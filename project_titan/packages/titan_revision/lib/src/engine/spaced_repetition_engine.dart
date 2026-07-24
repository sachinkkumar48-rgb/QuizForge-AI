import '../models/revision_models.dart';

/// Pure domain implementation of the SuperMemo-2 (SM-2) Spaced Repetition Algorithm.
class SpacedRepetitionEngine {
  const SpacedRepetitionEngine();

  /// Calculates the updated spaced repetition schedule for a [RevisionItem] given a user recall [qualityRating] (0 to 5).
  ///
  /// SM-2 Quality Scale:
  /// - 5: Perfect recall without hesitation.
  /// - 4: Correct response after minor hesitation.
  /// - 3: Correct response recalled with serious difficulty.
  /// - 2: Incorrect response; correct answer seemed easy to recall.
  /// - 1: Incorrect response; correct answer remembered.
  /// - 0: Complete blackout.
  SpacedRepetitionSchedule calculateNextSchedule(
    RevisionItem item,
    int qualityRating, {
    DateTime? reviewTimestamp,
  }) {
    final q = qualityRating.clamp(0, 5);
    final now = reviewTimestamp ?? DateTime.now();

    // 1. Calculate updated Ease Factor (EF)
    // Formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    double newEaseFactor =
        item.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }
    newEaseFactor = double.parse(newEaseFactor.toStringAsFixed(2));

    // 2. Calculate Repetitions & Interval
    int newRepetitions;
    int newIntervalDays;

    if (q < 3) {
      // Failed recall resets repetition count
      newRepetitions = 0;
      newIntervalDays = 1;
    } else {
      newRepetitions = item.repetitions + 1;
      if (newRepetitions == 1) {
        newIntervalDays = 1;
      } else if (newRepetitions == 2) {
        newIntervalDays = 6;
      } else {
        newIntervalDays = (item.intervalDays * newEaseFactor).round();
        if (newIntervalDays <= item.intervalDays) {
          newIntervalDays = item.intervalDays + 1;
        }
      }
    }

    final nextReviewDate = now.add(Duration(days: newIntervalDays));

    // 3. Determine Mastery Level
    final String masteryLevel;
    if (newIntervalDays >= 30 || (newRepetitions >= 4 && q >= 4)) {
      masteryLevel = 'Master';
    } else if (newIntervalDays >= 14 || newRepetitions >= 2) {
      masteryLevel = 'Proficient';
    } else if (q >= 3) {
      masteryLevel = 'Learning';
    } else {
      masteryLevel = 'Novice';
    }

    // 4. Determine Urgency Priority
    final String priority;
    if (q < 3) {
      priority = 'Urgent';
    } else if (masteryLevel == 'Learning') {
      priority = 'High';
    } else if (masteryLevel == 'Proficient') {
      priority = 'Medium';
    } else {
      priority = 'Low';
    }

    final updatedItem = item.copyWith(
      easeFactor: newEaseFactor,
      intervalDays: newIntervalDays,
      repetitions: newRepetitions,
      nextReviewDate: nextReviewDate,
      lastReviewedAt: now,
      qualityRating: q,
      masteryLevel: masteryLevel,
      priority: priority,
    );

    return SpacedRepetitionSchedule(
      updatedItem: updatedItem,
      calculatedEaseFactor: newEaseFactor,
      nextIntervalDays: newIntervalDays,
      nextReviewDate: nextReviewDate,
    );
  }
}
