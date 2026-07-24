class QuestionIdGenerator {
  /// Generate a globally unique, stable Question ID following format:
  /// `UPSC_PRE_GS1_2025_Q001`
  static String generateId({
    required String examCode,
    required String paperCode,
    required int year,
    required int questionIndex,
  }) {
    final cleanExam = _sanitizeCode(examCode);
    final cleanPaper = _sanitizeCode(paperCode);
    final paddedIndex = questionIndex.toString().padLeft(3, '0');
    return '${cleanExam}_${cleanPaper}_${year}_Q$paddedIndex';
  }

  /// Check if a given ID matches the stable structured identifier format and is non-numeric.
  static bool isStableFormat(String id) {
    if (id.trim().isEmpty) return false;
    // Reject plain numeric IDs (e.g. "1", "42")
    if (int.tryParse(id) != null) return false;

    // Check if ID matches pattern EXAM_PAPER_YEAR_Qxxx or contains structured string identifiers
    final regex =
        RegExp(r'^[A-Z0-9]+(_[A-Z0-9]+)*_\d{4}_Q\d{3,}$', caseSensitive: false);
    return regex.hasMatch(id.trim());
  }

  static String _sanitizeCode(String text) {
    final upper = text.toUpperCase().trim();
    // Common exam code simplifications
    if (upper.contains('UPSC')) return 'UPSC_PRE';
    if (upper.contains('BPSC')) return 'BPSC_PRE';
    if (upper.contains('GS') && upper.contains('1')) return 'GS1';
    if (upper.contains('GS') && upper.contains('2')) return 'GS2';
    if (upper.contains('CSAT')) return 'CSAT';

    return upper
        .replaceAll(RegExp(r'[^A-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
