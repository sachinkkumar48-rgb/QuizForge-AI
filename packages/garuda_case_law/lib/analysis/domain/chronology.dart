/// Chronology models for the Evidence-Bounded Cross-Case Analysis layer
/// (TITAN-KO-015.0 P10).
///
/// Deterministic chronological ordering of selected cases using the
/// authoritative existing case dates (judgment year, then judgment date).
/// Chronology is a structural observation — it never asserts legal
/// significance, overruling, refinement or evolution.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_knowledge_object.dart';

/// One case in a deterministic chronological sequence.
@immutable
class ChronologicalCaseEntry {
  /// Canonical corpus case ID.
  final String caseId;

  /// Display case name.
  final String caseName;

  /// Judgment year (authoritative ordering key).
  final int year;

  /// Judgment date from the record (secondary ordering key).
  final DateTime judgmentDate;

  /// 0-based position in the ordered sequence.
  final int position;

  /// The full validated case record (never fabricated).
  final CaseKnowledgeObject caseObject;

  const ChronologicalCaseEntry({
    required this.caseId,
    required this.caseName,
    required this.year,
    required this.judgmentDate,
    required this.position,
    required this.caseObject,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'year': year,
        'judgmentDate': judgmentDate.toIso8601String(),
        'position': position,
        'caseObject': caseObject.toJson(),
      };

  factory ChronologicalCaseEntry.fromJson(Map<String, dynamic> json) =>
      ChronologicalCaseEntry(
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        judgmentDate:
            DateTime.tryParse(json['judgmentDate'] as String? ?? '') ??
                DateTime(0),
        position: (json['position'] as num?)?.toInt() ?? 0,
        caseObject: CaseKnowledgeObject.fromJson(
            json['caseObject'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChronologicalCaseEntry && caseId == other.caseId;

  @override
  int get hashCode => caseId.hashCode;

  @override
  String toString() => 'ChronologicalCaseEntry($caseId, $year, pos $position)';
}

/// The deterministic chronological sequence of a selected set of cases.
@immutable
class ChronologyAnalysis {
  /// Cases ordered chronologically (year asc, judgment date asc, case name
  /// asc, case ID asc). Positions are 0-based.
  final List<ChronologicalCaseEntry> entries;

  /// Input identifiers that did not resolve to a corpus case.
  final List<String> unresolvedCaseIds;

  const ChronologyAnalysis({
    required this.entries,
    required this.unresolvedCaseIds,
  });

  bool get isEmpty => entries.isEmpty;

  /// Canonical case IDs in chronological order.
  List<String> get caseIds =>
      entries.map((e) => e.caseId).toList(growable: false);

  /// The chronologically earliest case, or null when empty.
  ChronologicalCaseEntry? get earliest =>
      entries.isEmpty ? null : entries.first;

  /// The chronologically latest case, or null when empty.
  ChronologicalCaseEntry? get latest => entries.isEmpty ? null : entries.last;

  /// Number of years between the latest and earliest judgment year, or null
  /// when the sequence is empty.
  int? get yearSpan {
    if (entries.isEmpty) return null;
    return entries.last.year - entries.first.year;
  }

  /// The 0-based position of [caseId] in the sequence, or null when absent.
  int? positionOf(String caseId) {
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].caseId == caseId) return i;
    }
    return null;
  }

  /// Cases strictly earlier than [caseId], in chronological order.
  List<ChronologicalCaseEntry> before(String caseId) {
    final pos = positionOf(caseId);
    if (pos == null) return const [];
    return entries.take(pos).toList(growable: false);
  }

  /// Cases strictly later than [caseId], in chronological order.
  List<ChronologicalCaseEntry> after(String caseId) {
    final pos = positionOf(caseId);
    if (pos == null) return const [];
    return entries.skip(pos + 1).toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'unresolvedCaseIds': unresolvedCaseIds,
      };

  factory ChronologyAnalysis.fromJson(Map<String, dynamic> json) =>
      ChronologyAnalysis(
        entries: (json['entries'] as List<dynamic>? ?? const [])
            .map((e) =>
                ChronologicalCaseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        unresolvedCaseIds:
            (json['unresolvedCaseIds'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
      );

  @override
  String toString() => 'ChronologyAnalysis(${entries.length} case(s))';
}
