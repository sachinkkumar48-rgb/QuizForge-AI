library;

import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';
import '../quality/quality_score_engine.dart';

class QualityGateResult {
  final bool isPassed;
  final List<String> blockingReasons;

  const QualityGateResult({
    required this.isPassed,
    required this.blockingReasons,
  });
}

class QualityGates {
  static const double minPublicationQualityScore = 80.0;

  static QualityGateResult validatePublicationGate(
    KnowledgeObject object, {
    bool hasDuplicateMatch = false,
    bool hasBrokenRelationships = false,
  }) {
    final List<String> reasons = [];

    // 1. Missing evidence
    if (object.evidenceIds.isEmpty) {
      reasons.add('Publication Blocked: Missing official evidence attachment.');
    }

    // 2. Broken relationships
    if (hasBrokenRelationships) {
      reasons.add('Publication Blocked: Broken relationship links detected.');
    }

    // 3. Duplicate objects
    if (hasDuplicateMatch) {
      reasons.add('Publication Blocked: Duplicate Knowledge Object detected.');
    }

    // 4. Missing official source
    if (object.officialSource.trim().isEmpty) {
      reasons.add('Publication Blocked: Missing official source citation.');
    }

    // 5. Failed validation
    if (object.title.trim().isEmpty || object.content.trim().isEmpty) {
      reasons.add('Publication Blocked: Object failed structural metadata validation.');
    }

    // 6. Missing editorial approval
    if (object.status != EditorialStatus.approved &&
        object.status != EditorialStatus.seniorEditorialReview &&
        object.status != EditorialStatus.published) {
      reasons.add('Publication Blocked: Missing required editorial approval (current status: ${object.status.displayName}).');
    }

    // 7. Quality Score threshold
    final breakdown = QualityScoreEngine.calculateScore(object);
    if (breakdown.totalScore < minPublicationQualityScore) {
      reasons.add(
          'Publication Blocked: Quality score (${breakdown.totalScore.toStringAsFixed(1)}) is below publication threshold ($minPublicationQualityScore).');
    }

    return QualityGateResult(
      isPassed: reasons.isEmpty,
      blockingReasons: reasons,
    );
  }
}
