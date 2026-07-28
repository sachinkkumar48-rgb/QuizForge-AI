import 'package:titan_ai/titan_ai.dart';

/// Detector for identifying content language in Knowledge Ingestion Pipeline.
class LanguageDetector {
  final AIService? aiService;

  LanguageDetector({this.aiService});

  /// Detects ISO language code (e.g., 'en', 'hi', 'es', 'fr', 'de').
  Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'en';

    // 1. Fast Devanagari / Hindi check
    final devanagariPattern = RegExp(r'[\u0900-\u097F]');
    final devanagariCount = devanagariPattern.allMatches(text).length;
    if (devanagariCount > text.length * 0.15) {
      return 'hi';
    }

    // 2. Common European language stopword heuristics
    final textLower = text.toLowerCase();
    if (RegExp(r'\b(el|la|los|las|por|para|con|del|una)\b')
            .hasMatch(textLower) &&
        !textLower.contains('the')) {
      return 'es';
    }
    if (RegExp(r'\b(le|la|les|des|du|dans|avec|pour)\b').hasMatch(textLower) &&
        !textLower.contains('the')) {
      return 'fr';
    }

    // 3. AI Service Fallback if configured
    if (aiService != null && text.length > 50) {
      try {
        final resp = await aiService!.generate<String>(
          AIRequest(
            prompt:
                'Detect ISO 639-1 language code (e.g. en, hi, es, fr) for text: "${text.substring(0, text.length > 200 ? 200 : text.length)}". Respond with 2-letter code only.',
            model: 'gemini-flash',
          ),
        );
        final code = resp.text.trim().toLowerCase();
        if (code.length == 2) {
          return code;
        }
      } catch (_) {
        // Fallback to default
      }
    }

    return 'en';
  }
}
