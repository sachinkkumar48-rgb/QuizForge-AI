import 'package:garuda_pyq/garuda_pyq.dart';

/// Tier classification for question quality and completeness.
enum QualityTier {
  gold,
  silver,
  bronze,
  draft,
}

extension QualityTierX on QualityTier {
  String get label {
    switch (this) {
      case QualityTier.gold:
        return 'Gold';
      case QualityTier.silver:
        return 'Silver';
      case QualityTier.bronze:
        return 'Bronze';
      case QualityTier.draft:
        return 'Draft';
    }
  }
}

/// Filter criteria for GARUDA Editorial Coverage Dashboard.
class CoverageFilter {
  final String? examId;
  final int? year;
  final String? subject;
  final String? topic;
  final String? difficulty;
  final EditorialStatus? editorialStatus;
  final QualityTier? confidenceTier;
  final String? language;

  const CoverageFilter({
    this.examId,
    this.year,
    this.subject,
    this.topic,
    this.difficulty,
    this.editorialStatus,
    this.confidenceTier,
    this.language,
  });

  bool get isEmpty =>
      examId == null &&
      year == null &&
      subject == null &&
      topic == null &&
      difficulty == null &&
      editorialStatus == null &&
      confidenceTier == null &&
      language == null;

  bool matches(Question question) {
    if (examId != null &&
        examId!.isNotEmpty &&
        question.examId.toLowerCase() != examId!.toLowerCase()) {
      return false;
    }
    if (year != null && question.year != year) {
      return false;
    }
    if (subject != null &&
        subject!.isNotEmpty &&
        question.subject.toLowerCase() != subject!.toLowerCase()) {
      return false;
    }
    if (topic != null &&
        topic!.isNotEmpty &&
        question.topic.toLowerCase() != topic!.toLowerCase()) {
      return false;
    }
    if (difficulty != null &&
        difficulty!.isNotEmpty &&
        question.difficulty.toLowerCase() != difficulty!.toLowerCase()) {
      return false;
    }
    if (editorialStatus != null && question.editorialStatus != editorialStatus) {
      return false;
    }
    if (confidenceTier != null) {
      final tier = computeQualityTier(question);
      if (tier != confidenceTier) return false;
    }
    if (language != null &&
        language!.isNotEmpty &&
        question.language.toLowerCase() != language!.toLowerCase()) {
      return false;
    }
    return true;
  }

  CoverageFilter copyWith({
    String? examId,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    EditorialStatus? editorialStatus,
    QualityTier? confidenceTier,
    String? language,
    bool clearExam = false,
    bool clearYear = false,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearDifficulty = false,
    bool clearEditorialStatus = false,
    bool clearConfidenceTier = false,
    bool clearLanguage = false,
  }) {
    return CoverageFilter(
      examId: clearExam ? null : (examId ?? this.examId),
      year: clearYear ? null : (year ?? this.year),
      subject: clearSubject ? null : (subject ?? this.subject),
      topic: clearTopic ? null : (topic ?? this.topic),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      editorialStatus: clearEditorialStatus ? null : (editorialStatus ?? this.editorialStatus),
      confidenceTier: clearConfidenceTier ? null : (confidenceTier ?? this.confidenceTier),
      language: clearLanguage ? null : (language ?? this.language),
    );
  }

  static QualityTier computeQualityTier(Question q) {
    final isVerified = q.verificationStatus.toLowerCase() == 'verified' ||
        q.editorialStatus == EditorialStatus.verified ||
        q.editorialStatus == EditorialStatus.answerVerified ||
        q.editorialStatus == EditorialStatus.published ||
        q.editorialStatus == EditorialStatus.readyForPublication;

    final isPublishedOrReady = q.editorialStatus == EditorialStatus.published ||
        q.editorialStatus == EditorialStatus.readyForPublication;

    final hasCompleteMetadata = q.trap != null &&
        q.learningObjectives != null &&
        (q.knowledgeObjectLinks.isNotEmpty ||
            q.articleLinks.isNotEmpty ||
            q.actLinks.isNotEmpty ||
            q.caseLinks.isNotEmpty);

    if (isPublishedOrReady && isVerified && hasCompleteMetadata) {
      return QualityTier.gold;
    }
    if (isVerified &&
        (q.conceptsTested.isNotEmpty ||
            q.coreConcepts.isNotEmpty ||
            q.garudaExplanation.isNotEmpty)) {
      return QualityTier.silver;
    }
    if (isVerified || q.editorialStatus == EditorialStatus.answerVerified) {
      return QualityTier.bronze;
    }
    return QualityTier.draft;
  }
}
