import '../pipeline/text_normalizer.dart';
import 'previous_year_question.dart';

/// Metadata extraction component for Previous Year Questions in TITAN PIE.
///
/// Responsible for subject detection, topic extraction, difficulty inference,
/// and metadata payload construction.
class PYQMetadataExtractor {
  final TextNormalizer _normalizer;

  /// Constructs a [PYQMetadataExtractor] with optional [TextNormalizer].
  PYQMetadataExtractor({TextNormalizer? normalizer})
      : _normalizer = normalizer ?? TextNormalizer();

  /// Detects or normalizes the subject domain of a [PreviousYearQuestion].
  String detectSubject(PreviousYearQuestion question) {
    final rawSubject = question.subject.trim();
    if (rawSubject.isNotEmpty && rawSubject != 'General') {
      return rawSubject;
    }

    final combinedText =
        '${question.question} ${question.explanation} ${question.topics.join(' ')}'
            .toLowerCase();

    if (combinedText.contains('rbi') ||
        combinedText.contains('inflation') ||
        combinedText.contains('gdp') ||
        combinedText.contains('fiscal') ||
        combinedText.contains('tax') ||
        combinedText.contains('economy')) {
      return 'Economy';
    } else if (combinedText.contains('constitution') ||
        combinedText.contains('preamble') ||
        combinedText.contains('parliament') ||
        combinedText.contains('governor') ||
        combinedText.contains('judiciary') ||
        combinedText.contains('article') ||
        combinedText.contains('polity')) {
      return 'Polity';
    } else if (combinedText.contains('biodiversity') ||
        combinedText.contains('species') ||
        combinedText.contains('forest') ||
        combinedText.contains('climate') ||
        combinedText.contains('pollution') ||
        combinedText.contains('environment')) {
      return 'Environment';
    } else if (combinedText.contains('dynasty') ||
        combinedText.contains('gupta') ||
        combinedText.contains('mughal') ||
        combinedText.contains('indus') ||
        combinedText.contains('british') ||
        combinedText.contains('history')) {
      return 'History';
    } else if (combinedText.contains('monsoon') ||
        combinedText.contains('river') ||
        combinedText.contains('plateau') ||
        combinedText.contains('soil') ||
        combinedText.contains('geography')) {
      return 'Geography';
    } else if (combinedText.contains('isro') ||
        combinedText.contains('satellite') ||
        combinedText.contains('quantum') ||
        combinedText.contains('dna') ||
        combinedText.contains('vaccine') ||
        combinedText.contains('technology')) {
      return 'Science & Technology';
    }

    return rawSubject.isNotEmpty ? rawSubject : 'General';
  }

  /// Detects topic keywords from question prompt and explanation.
  List<String> detectTopics(PreviousYearQuestion question) {
    final topicSet = <String>{};

    for (final topic in question.topics) {
      final clean = _normalizer.normalize(topic);
      if (clean.isNotEmpty) {
        topicSet.add(clean);
      }
    }

    final subject = detectSubject(question);
    if (subject.isNotEmpty && subject != 'General') {
      topicSet.add(subject);
    }

    return topicSet.toList();
  }

  /// Infers difficulty level ('Easy', 'Medium', 'Hard') for a [PreviousYearQuestion].
  String inferDifficulty(PreviousYearQuestion question) {
    final rawDifficulty = question.difficulty.trim();
    if (rawDifficulty.isNotEmpty && rawDifficulty != 'Medium') {
      return rawDifficulty;
    }

    final prompt = question.question;

    // Multi-statement questions with complex options are typically Hard
    if (prompt.contains('1 only') ||
        prompt.contains('1 and 2') ||
        prompt.contains('Neither 1 nor 2') ||
        prompt.contains('Which of the statements given above is/are correct') ||
        prompt.length > 350) {
      return 'Hard';
    } else if (prompt.length < 100 && question.options.length <= 4) {
      return 'Easy';
    }

    return 'Medium';
  }

  /// Merges exam, year, paper, subject, topics, and difficulty into a clean tags list.
  List<String> extractTags(PreviousYearQuestion question) {
    final tagSet = <String>{};

    for (final tag in question.tags) {
      final clean = _normalizer.normalize(tag);
      if (clean.isNotEmpty) {
        tagSet.add(clean);
      }
    }

    if (question.exam.isNotEmpty) {
      tagSet.add(question.exam.trim());
    }

    tagSet.add('${question.year}');
    tagSet.add('PYQ ${question.year}');

    if (question.paper.isNotEmpty) {
      tagSet.add(question.paper.trim());
    }

    final subject = detectSubject(question);
    if (subject.isNotEmpty && subject != 'General') {
      tagSet.add(subject);
    }

    tagSet.add(inferDifficulty(question));

    return tagSet.toList();
  }

  /// Extracts structured metadata map from [question].
  Map<String, dynamic> extractMetadata(PreviousYearQuestion question) {
    final detectedSubj = detectSubject(question);
    final detectedTop = detectTopics(question);
    final inferredDiff = inferDifficulty(question);
    final cleanTags = extractTags(question);

    return {
      'itemId': question.id,
      'exam': question.exam,
      'year': question.year,
      'paper': question.paper,
      'subject': detectedSubj,
      'topics': detectedTop,
      'difficulty': inferredDiff,
      'tags': cleanTags,
      'options': question.options,
      'answer': question.answer,
      'explanation': question.explanation,
      'contentType': 'pyq',
    };
  }
}
