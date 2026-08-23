import 'package:meta/meta.dart';

/// Target script categories for OCR line-level routing.
enum LineScript {
  /// Latin / English script family.
  latin,

  /// Devanagari / Hindi script family.
  devanagari,

  /// Mixed / bilingual script line (e.g. English + Hindi on same line).
  mixed,

  /// Ambiguous, numeric-only, punctuation-only, or unrecognized script.
  unknown,
}

/// Immutable result of a line-level script classification task.
@immutable
class ScriptClassificationResult {
  /// The resolved primary script for OCR routing.
  final LineScript script;

  /// Confidence score for the classification (0.0 to 1.0).
  final double confidence;

  /// Total character count analyzed in the line (including whitespace/digits).
  final int characterCount;

  /// Count of identifiable script letters (excluding whitespace/punctuation/digits).
  final int scriptCharacterCount;

  /// Proportion of script characters belonging to the dominant script (0.0 to 1.0).
  final double dominantRatio;

  /// The dominant script in mixed-script scenarios, or null if uniform/unknown.
  final LineScript? dominantScript;

  /// Diagnostic rationale explaining the classification decision.
  final String reason;

  const ScriptClassificationResult({
    required this.script,
    required this.confidence,
    required this.characterCount,
    required this.scriptCharacterCount,
    required this.dominantRatio,
    this.dominantScript,
    required this.reason,
  });

  /// Quick predicate checking if the line is classified as Devanagari.
  bool get isDevanagari =>
      script == LineScript.devanagari ||
      dominantScript == LineScript.devanagari;

  /// Quick predicate checking if the line is classified as Latin.
  bool get isLatin =>
      script == LineScript.latin || dominantScript == LineScript.latin;

  /// Quick predicate checking if the line contains mixed/bilingual text.
  bool get isBilingual => script == LineScript.mixed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScriptClassificationResult &&
          runtimeType == other.runtimeType &&
          script == other.script &&
          confidence == other.confidence &&
          characterCount == other.characterCount &&
          scriptCharacterCount == other.scriptCharacterCount &&
          dominantRatio == other.dominantRatio &&
          dominantScript == other.dominantScript &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(
        script,
        confidence,
        characterCount,
        scriptCharacterCount,
        dominantRatio,
        dominantScript,
        reason,
      );

  @override
  String toString() =>
      'ScriptClassificationResult(script: ${script.name}, conf: ${(confidence * 100).toStringAsFixed(1)}%, chars: $characterCount, reason: "$reason")';
}
