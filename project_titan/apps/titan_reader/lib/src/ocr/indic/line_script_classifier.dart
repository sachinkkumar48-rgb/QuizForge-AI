import 'dart:math' as math;

import '../../domain/entities/ocr/line_script_classification.dart';

/// Contract for deterministic OCR line script classification.
abstract class LineScriptClassifier {
  /// Analyzes raw or recognized line [text] and resolves its script category.
  ScriptClassificationResult classifyText(String text);
}

/// Production Unicode-range deterministic [LineScriptClassifier].
///
/// Operates 100% offline using standard Unicode character property ranges
/// to classify Latin, Devanagari, and mixed bilingual text lines without
/// external ML dependencies or network access.
class UnicodeLineScriptClassifier implements LineScriptClassifier {
  const UnicodeLineScriptClassifier();

  /// Minimum ratio threshold for declaring a script dominant in mixed lines (85%).
  static const double dominantThreshold = 0.85;

  @override
  ScriptClassificationResult classifyText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const ScriptClassificationResult(
        script: LineScript.unknown,
        confidence: 1.0,
        characterCount: 0,
        scriptCharacterCount: 0,
        dominantRatio: 0.0,
        reason: 'Empty line text.',
      );
    }

    int latinCount = 0;
    int devanagariCount = 0;
    int digitCount = 0;
    int otherCount = 0;

    for (final rune in trimmed.runes) {
      if (_isLatinLetter(rune)) {
        latinCount++;
      } else if (_isDevanagariLetter(rune)) {
        devanagariCount++;
      } else if (_isDigit(rune)) {
        digitCount++;
      } else {
        otherCount++;
      }
    }

    final totalChars = trimmed.runes.length;
    final scriptTotal = latinCount + devanagariCount;

    // Handle non-script lines (pure digits, punctuation, symbols)
    if (scriptTotal == 0) {
      if (digitCount > 0) {
        return ScriptClassificationResult(
          script: LineScript.unknown,
          confidence: 0.85,
          characterCount: totalChars,
          scriptCharacterCount: 0,
          dominantRatio: 0.0,
          reason:
              'Numeric digits only ($digitCount digits, $otherCount symbols).',
        );
      }
      return ScriptClassificationResult(
        script: LineScript.unknown,
        confidence: 0.90,
        characterCount: totalChars,
        scriptCharacterCount: 0,
        dominantRatio: 0.0,
        reason:
            'Punctuation or non-alphabetic symbols only ($otherCount chars).',
      );
    }

    // Pure Latin line
    if (latinCount > 0 && devanagariCount == 0) {
      final confidence = math.min(1.0, 0.70 + (latinCount / totalChars) * 0.30);
      return ScriptClassificationResult(
        script: LineScript.latin,
        confidence: confidence,
        characterCount: totalChars,
        scriptCharacterCount: latinCount,
        dominantRatio: 1.0,
        dominantScript: LineScript.latin,
        reason: 'Pure Latin script text ($latinCount characters).',
      );
    }

    // Pure Devanagari line
    if (devanagariCount > 0 && latinCount == 0) {
      final confidence =
          math.min(1.0, 0.70 + (devanagariCount / totalChars) * 0.30);
      return ScriptClassificationResult(
        script: LineScript.devanagari,
        confidence: confidence,
        characterCount: totalChars,
        scriptCharacterCount: devanagariCount,
        dominantRatio: 1.0,
        dominantScript: LineScript.devanagari,
        reason: 'Pure Devanagari script text ($devanagariCount characters).',
      );
    }

    // Mixed script line (both Latin and Devanagari present)
    final latinRatio = latinCount / scriptTotal;
    final devanagariRatio = devanagariCount / scriptTotal;

    if (devanagariRatio >= dominantThreshold) {
      return ScriptClassificationResult(
        script: LineScript.devanagari,
        confidence: 0.85,
        characterCount: totalChars,
        scriptCharacterCount: scriptTotal,
        dominantRatio: devanagariRatio,
        dominantScript: LineScript.devanagari,
        reason:
            'Devanagari dominant (${(devanagariRatio * 100).toStringAsFixed(1)}% Devanagari, $latinCount Latin chars).',
      );
    }

    if (latinRatio >= dominantThreshold) {
      return ScriptClassificationResult(
        script: LineScript.latin,
        confidence: 0.85,
        characterCount: totalChars,
        scriptCharacterCount: scriptTotal,
        dominantRatio: latinRatio,
        dominantScript: LineScript.latin,
        reason:
            'Latin dominant (${(latinRatio * 100).toStringAsFixed(1)}% Latin, $devanagariCount Devanagari chars).',
      );
    }

    final dominant = devanagariRatio >= latinRatio
        ? LineScript.devanagari
        : LineScript.latin;
    final maxRatio = math.max(latinRatio, devanagariRatio);

    return ScriptClassificationResult(
      script: LineScript.mixed,
      confidence: 0.90,
      characterCount: totalChars,
      scriptCharacterCount: scriptTotal,
      dominantRatio: maxRatio,
      dominantScript: dominant,
      reason:
          'Bilingual mixed script line ($devanagariCount Devanagari, $latinCount Latin).',
    );
  }

  /// Evaluates whether a Unicode rune is an alphabetic Latin letter.
  static bool _isLatinLetter(int rune) {
    // Basic Latin uppercase ('A'..'Z') and lowercase ('a'..'z')
    if ((rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A)) {
      return true;
    }
    // Latin-1 Supplement letters
    if ((rune >= 0x00C0 && rune <= 0x00D6) ||
        (rune >= 0x00D8 && rune <= 0x00F6) ||
        (rune >= 0x00F8 && rune <= 0x00FF)) {
      return true;
    }
    // Latin Extended-A & Latin Extended-B
    if (rune >= 0x0100 && rune <= 0x024F) {
      return true;
    }
    return false;
  }

  /// Evaluates whether a Unicode rune is a Devanagari script glyph.
  static bool _isDevanagariLetter(int rune) {
    // Devanagari block (U+0900..U+097F) excluding Devanagari digits (U+0966..U+096F) and danda
    if (rune >= 0x0900 && rune <= 0x097F) {
      if (rune >= 0x0966 && rune <= 0x096F) return false; // Digits
      if (rune == 0x0964 || rune == 0x0965) return false; // Danda punctuation
      return true;
    }
    // Devanagari Extended (U+A8E0..U+A8FF)
    if (rune >= 0xA8E0 && rune <= 0xA8FF) {
      return true;
    }
    // Vedic Extensions (U+1CD0..U+1CFF)
    if (rune >= 0x1CD0 && rune <= 0x1CFF) {
      return true;
    }
    return false;
  }

  /// Evaluates whether a Unicode rune is a numeric digit.
  static bool _isDigit(int rune) {
    // ASCII digits ('0'..'9')
    if (rune >= 0x0030 && rune <= 0x0039) return true;
    // Devanagari digits ('०'..'९')
    if (rune >= 0x0966 && rune <= 0x096F) return true;
    return false;
  }
}
