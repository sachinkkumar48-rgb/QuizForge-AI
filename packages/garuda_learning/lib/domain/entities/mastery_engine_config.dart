/// Mastery Engine Configuration Domain Entity (TITAN-KO-040.0 P40).
///
/// Immutable configuration model containing all tunable parameters driving
/// the deterministic progressive mastery update algorithm.
library;

import 'package:meta/meta.dart';

import 'mastery_classification.dart';
import 'mastery_exceptions.dart';

/// Tunable parameters for progressive mastery estimation and classification.
@immutable
class MasteryEngineConfig {
  /// Base mastery score assigned to an unattempted topic upon first exposure.
  final double initialMastery;

  /// Absolute minimum allowed mastery score.
  final double minMastery;

  /// Absolute maximum allowed mastery score.
  final double maxMastery;

  /// Base increment added to mastery score upon a correct response.
  final double correctIncrement;

  /// Base decrement subtracted from mastery score upon an incorrect response.
  final double incorrectDecrement;

  /// Weighting multiplier applied to 'Easy' questions (default: 0.8).
  final double easyDifficultyWeight;

  /// Weighting multiplier applied to 'Medium' questions (default: 1.0).
  final double mediumDifficultyWeight;

  /// Weighting multiplier applied to 'Hard' questions (default: 1.3).
  final double hardDifficultyWeight;

  /// Half-life in days for recency weighting decay (0 = no recency decay).
  final double recencyHalfLifeDays;

  /// Confidence score gained per evaluated evidence item.
  final double confidenceGrowthRate;

  /// Confidence penalty per consecutive incorrect answer.
  final double confidenceDecayRate;

  /// Absolute maximum confidence score (typically 1.0).
  final double maxConfidence;

  /// Minimum evidence count required before a topic can be classified as 'proficient'.
  final int minEvidenceForProficiency;

  /// Minimum evidence count required before a topic can be classified as 'mastered'.
  final int minEvidenceForMastery;

  /// Minimum confidence required before a topic can be classified as 'mastered'.
  final double minConfidenceForMastery;

  /// Score threshold at and above which mastery is classified as 'emerging'.
  final double emergingThreshold;

  /// Score threshold at and above which mastery is classified as 'developing'.
  final double developingThreshold;

  /// Score threshold at and above which mastery is classified as 'proficient'.
  final double proficientThreshold;

  /// Score threshold at and above which mastery is classified as 'mastered'.
  final double masteredThreshold;

  /// Sliding window size of recent attempts used to compute recentAccuracy.
  final int recentWindowSize;

  const MasteryEngineConfig({
    this.initialMastery = 0.15,
    this.minMastery = 0.0,
    this.maxMastery = 1.0,
    this.correctIncrement = 0.10,
    this.incorrectDecrement = 0.12,
    this.easyDifficultyWeight = 0.8,
    this.mediumDifficultyWeight = 1.0,
    this.hardDifficultyWeight = 1.3,
    this.recencyHalfLifeDays = 30.0,
    this.confidenceGrowthRate = 0.15,
    this.confidenceDecayRate = 0.05,
    this.maxConfidence = 1.0,
    this.minEvidenceForProficiency = 3,
    this.minEvidenceForMastery = 5,
    this.minConfidenceForMastery = 0.60,
    this.emergingThreshold = 0.25,
    this.developingThreshold = 0.50,
    this.proficientThreshold = 0.75,
    this.masteredThreshold = 0.90,
    this.recentWindowSize = 5,
  });

  /// Factory constructor that aggressively validates all invariants.
  factory MasteryEngineConfig.validated({
    double initialMastery = 0.15,
    double minMastery = 0.0,
    double maxMastery = 1.0,
    double correctIncrement = 0.10,
    double incorrectDecrement = 0.12,
    double easyDifficultyWeight = 0.8,
    double mediumDifficultyWeight = 1.0,
    double hardDifficultyWeight = 1.3,
    double recencyHalfLifeDays = 30.0,
    double confidenceGrowthRate = 0.15,
    double confidenceDecayRate = 0.05,
    double maxConfidence = 1.0,
    int minEvidenceForProficiency = 3,
    int minEvidenceForMastery = 5,
    double minConfidenceForMastery = 0.60,
    double emergingThreshold = 0.25,
    double developingThreshold = 0.50,
    double proficientThreshold = 0.75,
    double masteredThreshold = 0.90,
    int recentWindowSize = 5,
  }) {
    // 1. Min / Max bounds
    if (minMastery >= maxMastery) {
      throw InvalidMasteryConfigurationException(
        message:
            'minMastery ($minMastery) must be strictly less than maxMastery ($maxMastery)',
        details: {'minMastery': minMastery, 'maxMastery': maxMastery},
      );
    }
    if (initialMastery < minMastery || initialMastery > maxMastery) {
      throw InvalidMasteryConfigurationException(
        message:
            'initialMastery ($initialMastery) must be within [$minMastery, $maxMastery]',
        details: {'initialMastery': initialMastery},
      );
    }

    // 2. Step rates
    if (correctIncrement <= 0.0) {
      throw InvalidMasteryConfigurationException(
        message:
            'correctIncrement ($correctIncrement) must be strictly positive',
        details: {'correctIncrement': correctIncrement},
      );
    }
    if (incorrectDecrement <= 0.0) {
      throw InvalidMasteryConfigurationException(
        message:
            'incorrectDecrement ($incorrectDecrement) must be strictly positive',
        details: {'incorrectDecrement': incorrectDecrement},
      );
    }

    // 3. Difficulty weights
    if (easyDifficultyWeight <= 0.0 ||
        mediumDifficultyWeight <= 0.0 ||
        hardDifficultyWeight <= 0.0) {
      throw InvalidMasteryConfigurationException(
        message: 'Difficulty weights must be strictly positive',
        details: {
          'easy': easyDifficultyWeight,
          'medium': mediumDifficultyWeight,
          'hard': hardDifficultyWeight,
        },
      );
    }
    if (easyDifficultyWeight >= hardDifficultyWeight) {
      throw InvalidMasteryConfigurationException(
        message:
            'easyDifficultyWeight ($easyDifficultyWeight) must be less than hardDifficultyWeight ($hardDifficultyWeight)',
      );
    }

    // 4. Confidence bounds
    if (maxConfidence <= 0.0 || maxConfidence > 1.0) {
      throw InvalidMasteryConfigurationException(
        message: 'maxConfidence ($maxConfidence) must be in (0.0, 1.0]',
      );
    }
    if (confidenceGrowthRate <= 0.0) {
      throw InvalidMasteryConfigurationException(
        message: 'confidenceGrowthRate must be strictly positive',
      );
    }
    if (minConfidenceForMastery < 0.0 ||
        minConfidenceForMastery > maxConfidence) {
      throw InvalidMasteryConfigurationException(
        message:
            'minConfidenceForMastery ($minConfidenceForMastery) must be in [0.0, $maxConfidence]',
      );
    }

    // 5. Evidence counts
    if (minEvidenceForProficiency < 1 ||
        minEvidenceForMastery < minEvidenceForProficiency) {
      throw InvalidMasteryConfigurationException(
        message:
            'minEvidence counts must satisfy 1 <= proficiency ($minEvidenceForProficiency) <= mastery ($minEvidenceForMastery)',
      );
    }
    if (recentWindowSize < 1) {
      throw InvalidMasteryConfigurationException(
        message: 'recentWindowSize ($recentWindowSize) must be >= 1',
      );
    }

    // 6. Threshold progression
    if (!(minMastery <= emergingThreshold &&
        emergingThreshold < developingThreshold &&
        developingThreshold < proficientThreshold &&
        proficientThreshold < masteredThreshold &&
        masteredThreshold <= maxMastery)) {
      throw InvalidMasteryConfigurationException(
        message:
            'Classification thresholds must strictly ascend: min <= emerging ($emergingThreshold) < developing ($developingThreshold) < proficient ($proficientThreshold) < mastered ($masteredThreshold) <= max',
      );
    }

    return MasteryEngineConfig(
      initialMastery: initialMastery,
      minMastery: minMastery,
      maxMastery: maxMastery,
      correctIncrement: correctIncrement,
      incorrectDecrement: incorrectDecrement,
      easyDifficultyWeight: easyDifficultyWeight,
      mediumDifficultyWeight: mediumDifficultyWeight,
      hardDifficultyWeight: hardDifficultyWeight,
      recencyHalfLifeDays: recencyHalfLifeDays,
      confidenceGrowthRate: confidenceGrowthRate,
      confidenceDecayRate: confidenceDecayRate,
      maxConfidence: maxConfidence,
      minEvidenceForProficiency: minEvidenceForProficiency,
      minEvidenceForMastery: minEvidenceForMastery,
      minConfidenceForMastery: minConfidenceForMastery,
      emergingThreshold: emergingThreshold,
      developingThreshold: developingThreshold,
      proficientThreshold: proficientThreshold,
      masteredThreshold: masteredThreshold,
      recentWindowSize: recentWindowSize,
    );
  }

  /// Evaluates difficulty weighting factor deterministically for a difficulty string.
  double getDifficultyWeight(String difficulty) {
    switch (difficulty.trim().toLowerCase()) {
      case 'easy':
        return easyDifficultyWeight;
      case 'hard':
        return hardDifficultyWeight;
      case 'medium':
      default:
        return mediumDifficultyWeight;
    }
  }

  /// Classifies a mastery score into a [MasteryClassification] given confidence and evidence count.
  MasteryClassification classify({
    required double score,
    required double confidence,
    required int evidenceCount,
  }) {
    if (evidenceCount <= 0) {
      return MasteryClassification.notStarted;
    }
    if (score >= masteredThreshold &&
        confidence >= minConfidenceForMastery &&
        evidenceCount >= minEvidenceForMastery) {
      return MasteryClassification.mastered;
    }
    if (score >= proficientThreshold &&
        evidenceCount >= minEvidenceForProficiency) {
      return MasteryClassification.proficient;
    }
    if (score >= developingThreshold) {
      return MasteryClassification.developing;
    }
    if (score >= emergingThreshold) {
      return MasteryClassification.emerging;
    }
    return MasteryClassification.emerging;
  }

  Map<String, dynamic> toJson() => {
        'initialMastery': initialMastery,
        'minMastery': minMastery,
        'maxMastery': maxMastery,
        'correctIncrement': correctIncrement,
        'incorrectDecrement': incorrectDecrement,
        'easyDifficultyWeight': easyDifficultyWeight,
        'mediumDifficultyWeight': mediumDifficultyWeight,
        'hardDifficultyWeight': hardDifficultyWeight,
        'recencyHalfLifeDays': recencyHalfLifeDays,
        'confidenceGrowthRate': confidenceGrowthRate,
        'confidenceDecayRate': confidenceDecayRate,
        'maxConfidence': maxConfidence,
        'minEvidenceForProficiency': minEvidenceForProficiency,
        'minEvidenceForMastery': minEvidenceForMastery,
        'minConfidenceForMastery': minConfidenceForMastery,
        'emergingThreshold': emergingThreshold,
        'developingThreshold': developingThreshold,
        'proficientThreshold': proficientThreshold,
        'masteredThreshold': masteredThreshold,
        'recentWindowSize': recentWindowSize,
      };

  factory MasteryEngineConfig.fromJson(Map<String, dynamic> json) {
    return MasteryEngineConfig.validated(
      initialMastery: (json['initialMastery'] as num?)?.toDouble() ?? 0.15,
      minMastery: (json['minMastery'] as num?)?.toDouble() ?? 0.0,
      maxMastery: (json['maxMastery'] as num?)?.toDouble() ?? 1.0,
      correctIncrement: (json['correctIncrement'] as num?)?.toDouble() ?? 0.10,
      incorrectDecrement:
          (json['incorrectDecrement'] as num?)?.toDouble() ?? 0.12,
      easyDifficultyWeight:
          (json['easyDifficultyWeight'] as num?)?.toDouble() ?? 0.8,
      mediumDifficultyWeight:
          (json['mediumDifficultyWeight'] as num?)?.toDouble() ?? 1.0,
      hardDifficultyWeight:
          (json['hardDifficultyWeight'] as num?)?.toDouble() ?? 1.3,
      recencyHalfLifeDays:
          (json['recencyHalfLifeDays'] as num?)?.toDouble() ?? 30.0,
      confidenceGrowthRate:
          (json['confidenceGrowthRate'] as num?)?.toDouble() ?? 0.15,
      confidenceDecayRate:
          (json['confidenceDecayRate'] as num?)?.toDouble() ?? 0.05,
      maxConfidence: (json['maxConfidence'] as num?)?.toDouble() ?? 1.0,
      minEvidenceForProficiency:
          (json['minEvidenceForProficiency'] as num?)?.toInt() ?? 3,
      minEvidenceForMastery:
          (json['minEvidenceForMastery'] as num?)?.toInt() ?? 5,
      minConfidenceForMastery:
          (json['minConfidenceForMastery'] as num?)?.toDouble() ?? 0.60,
      emergingThreshold:
          (json['emergingThreshold'] as num?)?.toDouble() ?? 0.25,
      developingThreshold:
          (json['developingThreshold'] as num?)?.toDouble() ?? 0.50,
      proficientThreshold:
          (json['proficientThreshold'] as num?)?.toDouble() ?? 0.75,
      masteredThreshold:
          (json['masteredThreshold'] as num?)?.toDouble() ?? 0.90,
      recentWindowSize: (json['recentWindowSize'] as num?)?.toInt() ?? 5,
    );
  }
}
