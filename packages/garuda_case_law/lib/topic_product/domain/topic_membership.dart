/// Topic membership for the Evidence-Bounded UPSC Topic Knowledge Product layer
/// (TITAN-KO-015.0 P14).
///
/// A [TopicMembership] is the explicit, deterministic P14 record that a case
/// belongs to a pedagogical topic. It is the ONLY way a case enters a topic:
/// membership is never inferred from an Article mention, a doctrine edge, a
/// graph relationship, discovery, chronology or apparent relevance. Each
/// membership cites the specific validated source field and value (the
/// "signal") that the case genuinely carries and that justifies the grouping.
///
/// Topic membership is a pedagogical grouping and does NOT establish a legal
/// relationship between the included entities.
library;

import 'package:meta/meta.dart';

/// The validated source fields a P14 membership signal may cite.
///
/// These are the exact P3/P4 fields a case carries; a membership is valid only
/// when the cited [TopicMembership.signalValue] is genuinely present in the
/// cited field on the case. Field keys are the provenance prefix used in
/// statements (e.g. `p4:mainsThemes`).
abstract final class TopicSignalField {
  /// `CaseKnowledgeObject.themes` (P3).
  static const String p3Themes = 'p3:themes';

  /// `CaseKnowledgeObject.subjects` (P3).
  static const String p3Subjects = 'p3:subjects';

  /// `UpscJudgmentIntelligence.mainsThemes` (P4).
  static const String p4MainsThemes = 'p4:mainsThemes';

  /// `UpscJudgmentIntelligence.answerKeywords` (P4).
  static const String p4AnswerKeywords = 'p4:answerKeywords';

  /// `UpscJudgmentIntelligence.essayThemes` (P4).
  static const String p4EssayThemes = 'p4:essayThemes';

  /// `UpscJudgmentIntelligence.relatedSyllabusAreas` (P4).
  static const String p4SyllabusAreas = 'p4:syllabusAreas';

  /// All supported signal fields, sorted, for validation.
  static const List<String> all = [
    p3Themes,
    p3Subjects,
    p4MainsThemes,
    p4AnswerKeywords,
    p4EssayThemes,
    p4SyllabusAreas,
  ];
}

/// One explicit, evidence-bounded case → topic mapping record.
@immutable
class TopicMembership {
  /// The canonical P14 topic ID the case is grouped under.
  final String topicId;

  /// The canonical corpus case ID being mapped.
  final String caseId;

  /// The validated source field cited (one of [TopicSignalField]).
  final String signalField;

  /// The exact validated value the case carries in [signalField] — verbatim
  /// from the case record, never re-formatted.
  final String signalValue;

  /// Optional deterministic editorial note explaining the pedagogical grouping.
  final String note;

  const TopicMembership({
    required this.topicId,
    required this.caseId,
    required this.signalField,
    required this.signalValue,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'caseId': caseId,
        'signalField': signalField,
        'signalValue': signalValue,
        if (note.isNotEmpty) 'note': note,
      };

  factory TopicMembership.fromJson(Map<String, dynamic> json) =>
      TopicMembership(
        topicId: json['topicId'] as String? ?? '',
        caseId: json['caseId'] as String? ?? '',
        signalField: json['signalField'] as String? ?? '',
        signalValue: json['signalValue'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicMembership &&
          topicId == other.topicId &&
          caseId == other.caseId &&
          signalField == other.signalField &&
          signalValue == other.signalValue &&
          note == other.note;

  @override
  int get hashCode =>
      Object.hash(topicId, caseId, signalField, signalValue, note);

  @override
  String toString() => 'TopicMembership($caseId → $topicId)';
}
