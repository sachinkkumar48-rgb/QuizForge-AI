library;

class ParsedMetadata {
  final String examId;
  final int year;
  final String stage;
  final String paper;
  final String subject;
  final String topic;
  final String? subtopic;
  final String language;

  const ParsedMetadata({
    required this.examId,
    required this.year,
    required this.stage,
    required this.paper,
    required this.subject,
    required this.topic,
    this.subtopic,
    this.language = 'en',
  });
}

class MetadataExtractor {
  /// Extracts exam metadata from filename or header text.
  static ParsedMetadata extract({
    required String filename,
    required String headerText,
    Map<String, dynamic> defaultMetadata = const {},
  }) {
    final combined = '$filename\n$headerText'.toLowerCase();

    String examId = defaultMetadata['examId'] as String? ?? 'upsc_cse';
    if (RegExp(r'\bcds\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'upsc_cds';
    } else if (RegExp(r'\bnda\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'upsc_nda';
    } else if (RegExp(r'\bcapf\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'upsc_capf';
    } else if (RegExp(r'\bepfo\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'upsc_epfo';
    } else if (RegExp(r'\brbi\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'rbi_grade_b';
    } else if (RegExp(r'\bnabard\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'nabard_grade_a';
    } else if (RegExp(r'\bsebi\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'sebi_grade_a';
    } else if (RegExp(r'\bssc\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'ssc_cgl';
    } else if (RegExp(r'\b(?:state_psc|uppsc|mppsc|bpsc|tnpsc|wbcs)\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'state_psc';
    } else if (RegExp(r'\bupsc\b', caseSensitive: false).hasMatch(combined)) {
      examId = 'upsc_cse';
    }

    final yearMatch = RegExp(r'\b(199[5-9]|20[0-2][0-9])\b').firstMatch(combined);
    final year = defaultMetadata['year'] as int? ?? (yearMatch != null ? int.parse(yearMatch.group(0)!) : 2024);

    String subject = defaultMetadata['subject'] as String? ?? 'General Studies';
    if (combined.contains('polity') || combined.contains('constitution')) {
      subject = 'Polity';
    } else if (combined.contains('economy') || combined.contains('banking')) {
      subject = 'Economy';
    } else if (combined.contains('environment') || combined.contains('ecology')) {
      subject = 'Environment';
    } else if (combined.contains('history') || combined.contains('freedom')) {
      subject = 'History';
    } else if (combined.contains('geography') || combined.contains('climate')) {
      subject = 'Geography';
    } else if (combined.contains('science') || combined.contains('tech')) {
      subject = 'Science & Tech';
    }

    return ParsedMetadata(
      examId: examId,
      year: year,
      stage: defaultMetadata['stage'] as String? ?? 'Prelims',
      paper: defaultMetadata['paper'] as String? ?? 'GS Paper I',
      subject: subject,
      topic: defaultMetadata['topic'] as String? ?? '$subject Core Concepts',
      subtopic: defaultMetadata['subtopic'] as String?,
      language: defaultMetadata['language'] as String? ?? 'en',
    );
  }
}
