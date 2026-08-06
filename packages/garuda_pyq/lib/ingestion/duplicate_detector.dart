import '../models/question_model.dart';

class DuplicateDetector {
  /// Returns list of duplicate questions found based on ID, checksum, or question text.
  static List<Question> findDuplicates(
    List<Question> existing,
    List<Question> incoming,
  ) {
    final duplicates = <Question>[];
    final existingIds = existing.map((q) => q.id).toSet();
    final existingChecksums =
        existing.map((q) => q.source.checksum).where((c) => c.isNotEmpty).toSet();
    final existingTexts =
        existing.map((q) => _normalizeText(q.originalQuestion)).toSet();

    for (final inc in incoming) {
      final normalizedIncText = _normalizeText(inc.originalQuestion);
      if (existingIds.contains(inc.id) ||
          (inc.source.checksum.isNotEmpty &&
              existingChecksums.contains(inc.source.checksum)) ||
          existingTexts.contains(normalizedIncText)) {
        duplicates.add(inc);
      }
    }

    return duplicates;
  }

  static String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }
}
