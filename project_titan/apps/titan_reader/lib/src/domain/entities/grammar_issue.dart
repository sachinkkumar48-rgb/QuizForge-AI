/// A single issue found by a grammar/spelling check.
///
/// Offsets are character offsets into the checked text (the selection that
/// was analyzed), never into the PDF itself. The PDF geometry link is the
/// page recorded on the source context by the Reader, not on the issue.
library;

import 'package:meta/meta.dart';

/// Category of a grammar issue. Only categories the active engine can
/// actually produce are used; nothing is invented per issue.
enum GrammarIssueType {
  /// Word not recognized by the spelling source.
  spelling,

  /// Grammar construction (agreement, modal + of, ...).
  grammar,

  /// Punctuation placement problems.
  punctuation,

  /// Typographical problems (double spaces, doubled punctuation, ...).
  typographical,

  /// Style-level observations (sentence capitalization, ...).
  style,
}

/// Coarse severity of an issue. The local deterministic engine assigns one
/// per rule; remote engines map their own categories onto these.
enum GrammarIssueSeverity { error, warning, suggestion }

/// Where an issue came from.
enum GrammarIssueSource {
  /// Produced by the bundled deterministic local engine.
  local,

  /// Produced by an optional remote engine (opt-in only).
  remote,
}

/// One replacement proposed for the flagged span.
@immutable
class GrammarSuggestion {
  /// The replacement text for the span `[startOffset, endOffset)`.
  final String replacement;

  /// Optional human-readable note describing the replacement.
  final String? label;

  const GrammarSuggestion({required this.replacement, this.label});

  Map<String, Object?> toJson() => <String, Object?>{
        'replacement': replacement,
        'label': label,
      };

  factory GrammarSuggestion.fromJson(Map<String, Object?> json) {
    final replacement = json['replacement'];
    if (replacement is! String) {
      throw const FormatException(
          'GrammarSuggestion JSON requires a replacement field.');
    }
    final label = json['label'];
    return GrammarSuggestion(
      replacement: replacement,
      label: label is String ? label : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrammarSuggestion &&
          runtimeType == other.runtimeType &&
          replacement == other.replacement &&
          label == other.label;

  @override
  int get hashCode => Object.hash(replacement, label);

  @override
  String toString() => 'GrammarSuggestion("$replacement")';
}

/// A single grammar/spelling issue with its span, message and suggestions.
@immutable
class GrammarIssue {
  /// Stable identifier of the rule that produced the issue (e.g.
  /// `spelling.unknown-word`, `rule.repeated-word`).
  final String ruleId;

  /// Issue category.
  final GrammarIssueType type;

  /// Coarse severity.
  final GrammarIssueSeverity severity;

  /// Short human-readable message.
  final String message;

  /// Longer deterministic explanation; null when the engine provides none.
  final String? explanation;

  /// Start offset into the checked text (inclusive).
  final int startOffset;

  /// End offset into the checked text (exclusive).
  final int endOffset;

  /// The flagged text span.
  final String originalText;

  /// Zero or more replacement suggestions.
  final List<GrammarSuggestion> suggestions;

  /// Engine that produced the issue.
  final GrammarIssueSource source;

  const GrammarIssue({
    required this.ruleId,
    required this.type,
    required this.severity,
    required this.message,
    required this.startOffset,
    required this.endOffset,
    required this.originalText,
    this.explanation,
    this.suggestions = const [],
    this.source = GrammarIssueSource.local,
  })  : assert(startOffset >= 0, 'startOffset must be >= 0'),
        assert(endOffset >= startOffset, 'endOffset must be >= startOffset');

  /// The flagged span as it appears inside [checkedText], or [originalText]
  /// when the offsets fall outside (defensive).
  String spanIn(String checkedText) {
    if (startOffset > checkedText.length || endOffset > checkedText.length) {
      return originalText;
    }
    return checkedText.substring(startOffset, endOffset);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'ruleId': ruleId,
        'type': type.name,
        'severity': severity.name,
        'message': message,
        'explanation': explanation,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'originalText': originalText,
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'source': source.name,
      };

  /// Deserializes a [GrammarIssue]; throws [FormatException] on malformed
  /// required fields and clamps offsets defensively.
  factory GrammarIssue.fromJson(Map<String, Object?> json) {
    final ruleId = json['ruleId'];
    final message = json['message'];
    final originalText = json['originalText'];
    final startOffset = json['startOffset'];
    final endOffset = json['endOffset'];
    if (ruleId is! String ||
        message is! String ||
        originalText is! String ||
        startOffset is! int ||
        endOffset is! int) {
      throw const FormatException(
          'GrammarIssue JSON requires ruleId, message, originalText, '
          'startOffset and endOffset fields.');
    }
    final type = GrammarIssueType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => GrammarIssueType.grammar,
    );
    final severity = GrammarIssueSeverity.values.firstWhere(
      (value) => value.name == json['severity'],
      orElse: () => GrammarIssueSeverity.warning,
    );
    final source = GrammarIssueSource.values.firstWhere(
      (value) => value.name == json['source'],
      orElse: () => GrammarIssueSource.local,
    );
    final explanation = json['explanation'];
    final rawSuggestions = json['suggestions'];
    final suggestions = rawSuggestions is List
        ? rawSuggestions
            .whereType<Map<String, Object?>>()
            .map(GrammarSuggestion.fromJson)
            .toList()
        : <GrammarSuggestion>[];
    final clampedStart = startOffset < 0 ? 0 : startOffset;
    final clampedEnd = endOffset < clampedStart ? clampedStart : endOffset;
    return GrammarIssue(
      ruleId: ruleId,
      type: type,
      severity: severity,
      message: message,
      explanation: explanation is String ? explanation : null,
      startOffset: clampedStart,
      endOffset: clampedEnd,
      originalText: originalText,
      suggestions: List.unmodifiable(suggestions),
      source: source,
    );
  }

  @override
  String toString() =>
      'GrammarIssue($ruleId, $startOffset..$endOffset, "$originalText")';
}

/// Result of checking one text.
@immutable
class GrammarCheckResult {
  /// The text that was checked.
  final String text;

  /// BCP-47-ish language code the check ran for (always `en` in Phase 4).
  final String language;

  /// Issues ordered by [GrammarIssue.startOffset] then [GrammarIssue.endOffset].
  final List<GrammarIssue> issues;

  /// Identifier of the local engine that produced the local issues.
  final String engineId;

  /// Version of the local engine (part of the cache key so engine updates
  /// never serve stale results).
  final String engineVersion;

  /// Identifier of the remote engine whose issues are merged in, if any.
  final String? remoteSourceId;

  /// When the check ran.
  final DateTime checkedAt;

  const GrammarCheckResult({
    required this.text,
    required this.language,
    required this.issues,
    required this.engineId,
    required this.engineVersion,
    required this.checkedAt,
    this.remoteSourceId,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'text': text,
        'language': language,
        'engineId': engineId,
        'engineVersion': engineVersion,
        'remoteSourceId': remoteSourceId,
        'checkedAt': checkedAt.toIso8601String(),
        'issues': issues.map((issue) => issue.toJson()).toList(),
      };

  /// Deserializes a [GrammarCheckResult]; throws [FormatException] on
  /// malformed required fields.
  factory GrammarCheckResult.fromJson(Map<String, Object?> json) {
    final text = json['text'];
    final language = json['language'];
    final engineId = json['engineId'];
    final engineVersion = json['engineVersion'];
    final checkedAt = json['checkedAt'];
    if (text is! String ||
        language is! String ||
        engineId is! String ||
        engineVersion is! String ||
        checkedAt is! String) {
      throw const FormatException(
          'GrammarCheckResult JSON requires text, language, engineId, '
          'engineVersion and checkedAt fields.');
    }
    final rawIssues = json['issues'];
    final issues = rawIssues is List
        ? rawIssues
            .whereType<Map<String, Object?>>()
            .map(GrammarIssue.fromJson)
            .toList()
        : <GrammarIssue>[];
    issues.sort((a, b) {
      final byStart = a.startOffset.compareTo(b.startOffset);
      if (byStart != 0) return byStart;
      return a.endOffset.compareTo(b.endOffset);
    });
    final remoteSourceId = json['remoteSourceId'];
    return GrammarCheckResult(
      text: text,
      language: language,
      issues: List.unmodifiable(issues),
      engineId: engineId,
      engineVersion: engineVersion,
      remoteSourceId: remoteSourceId is String ? remoteSourceId : null,
      checkedAt: DateTime.parse(checkedAt),
    );
  }
}

/// A Reader-managed correction accepted by the user.
///
/// A rendered PDF is not an editable text document: applying a suggestion
/// never modifies the original PDF file. Corrections are Reader-owned
/// records pairing the original selection with the corrected version so the
/// user can review and copy them later (Phase 6 owns real PDF editing).
@immutable
class GrammarCorrection {
  /// Unique correction id.
  final String id;

  /// Document the corrected selection came from, if known.
  final String? documentId;

  /// Page of the corrected selection, if known.
  final int? pageNumber;

  /// The original selected text.
  final String originalText;

  /// The corrected text (original with accepted replacements applied).
  final String correctedText;

  /// Rule ids of the accepted issues, for traceability.
  final List<String> appliedRuleIds;

  /// When the correction was accepted.
  final DateTime createdAt;

  const GrammarCorrection({
    required this.id,
    required this.originalText,
    required this.correctedText,
    required this.appliedRuleIds,
    required this.createdAt,
    this.documentId,
    this.pageNumber,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'originalText': originalText,
        'correctedText': correctedText,
        'appliedRuleIds': appliedRuleIds,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserializes a [GrammarCorrection]; throws [FormatException] on
  /// malformed required fields.
  factory GrammarCorrection.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final originalText = json['originalText'];
    final correctedText = json['correctedText'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        originalText is! String ||
        correctedText is! String ||
        createdAt is! String) {
      throw const FormatException(
          'GrammarCorrection JSON requires id, originalText, correctedText '
          'and createdAt fields.');
    }
    final documentId = json['documentId'];
    final pageNumber = json['pageNumber'];
    final rawRuleIds = json['appliedRuleIds'];
    return GrammarCorrection(
      id: id,
      documentId: documentId is String ? documentId : null,
      pageNumber: pageNumber is int ? pageNumber : null,
      originalText: originalText,
      correctedText: correctedText,
      appliedRuleIds: rawRuleIds is List
          ? List.unmodifiable(rawRuleIds.whereType<String>())
          : const [],
      createdAt: DateTime.parse(createdAt),
    );
  }

  @override
  String toString() => 'GrammarCorrection($id, page: $pageNumber)';
}
