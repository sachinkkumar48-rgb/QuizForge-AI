import '../pipeline/text_normalizer.dart';
import 'current_affairs_item.dart';
import 'current_affairs_validation_result.dart';

/// Validator, normalizer, category identifier, and metadata extractor component
/// for Current Affairs items in TITAN CAIE.
class CurrentAffairsParser {
  final TextNormalizer _normalizer;

  /// Constructs a [CurrentAffairsParser] with optional [TextNormalizer].
  CurrentAffairsParser({TextNormalizer? normalizer})
      : _normalizer = normalizer ?? TextNormalizer();

  /// Validates a [CurrentAffairsItem] and returns a [CurrentAffairsValidationResult].
  CurrentAffairsValidationResult validate(CurrentAffairsItem item) {
    final errors = <String>[];
    final warnings = <String>[];

    if (item.id.trim().isEmpty) {
      errors.add('CurrentAffairsItem id cannot be empty or whitespace.');
    }

    if (item.title.trim().isEmpty) {
      errors.add('CurrentAffairsItem title cannot be empty or whitespace.');
    }

    if (item.content.trim().isEmpty) {
      errors.add('CurrentAffairsItem content cannot be empty or whitespace.');
    }

    if (item.source.trim().isEmpty || item.source == 'Unknown') {
      warnings.add('Source attribution is unspecified or unknown.');
    }

    if (item.summary.trim().isEmpty) {
      warnings.add('Summary is empty; fallback summary will be generated.');
    }

    if (item.tags.isEmpty) {
      warnings.add('No topic tags assigned.');
    }

    return CurrentAffairsValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      statistics: {
        'itemId': item.id,
        'contentLength': item.content.length,
        'tagCount': item.tags.length,
      },
    );
  }

  /// Normalizes input strings, whitespace, CRLF formatting, tags, and subjects.
  CurrentAffairsItem normalize(CurrentAffairsItem item) {
    final normalizedTitle = _normalizer.normalize(item.title);
    final normalizedSummary = _normalizer.normalize(item.summary);
    final normalizedContent = _normalizer.normalize(item.content);
    final normalizedSource = item.source.trim();
    final normalizedCategory = identifyCategory(item);
    final cleanTags = assignTags(item);

    final cleanSubjects = item.relatedSubjects
        .map((s) => _normalizer.normalize(s))
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    return item.copyWith(
      title: normalizedTitle,
      summary: normalizedSummary,
      content: normalizedContent,
      source: normalizedSource,
      category: normalizedCategory,
      tags: cleanTags,
      relatedSubjects: cleanSubjects,
    );
  }

  /// Identifies and normalizes the domain category of a [CurrentAffairsItem].
  String identifyCategory(CurrentAffairsItem item) {
    final rawCategory = item.category.trim();
    if (rawCategory.isNotEmpty && rawCategory != 'General') {
      return rawCategory;
    }

    final combinedText =
        '${item.title} ${item.content} ${item.tags.join(' ')}'.toLowerCase();

    if (combinedText.contains('rbi') ||
        combinedText.contains('monetary') ||
        combinedText.contains('gdp') ||
        combinedText.contains('inflation') ||
        combinedText.contains('economy')) {
      return 'Economy';
    } else if (combinedText.contains('court') ||
        combinedText.contains('judiciary') ||
        combinedText.contains('constitution') ||
        combinedText.contains('polity') ||
        combinedText.contains('bill')) {
      return 'Polity';
    } else if (combinedText.contains('climate') ||
        combinedText.contains('environment') ||
        combinedText.contains('forest') ||
        combinedText.contains('pollution') ||
        combinedText.contains('wetland')) {
      return 'Environment';
    } else if (combinedText.contains('treaty') ||
        combinedText.contains('diplomacy') ||
        combinedText.contains('summit') ||
        combinedText.contains('bilateral') ||
        combinedText.contains('unsc')) {
      return 'International Relations';
    } else if (combinedText.contains('isro') ||
        combinedText.contains('ai') ||
        combinedText.contains('satellite') ||
        combinedText.contains('technology') ||
        combinedText.contains('biotech')) {
      return 'Science & Technology';
    }

    return rawCategory.isNotEmpty ? rawCategory : 'General';
  }

  /// Assigns, cleans, and deduplicates tags for a [CurrentAffairsItem].
  List<String> assignTags(CurrentAffairsItem item) {
    final tagSet = <String>{};

    for (final tag in item.tags) {
      final cleaned = _normalizer.normalize(tag);
      if (cleaned.isNotEmpty) {
        tagSet.add(cleaned);
      }
    }

    final category = identifyCategory(item);
    if (category.isNotEmpty && category != 'General') {
      tagSet.add(category);
    }

    return tagSet.toList();
  }

  /// Extracts structured metadata from [item] preserving attribution and dates.
  Map<String, dynamic> extractMetadata(CurrentAffairsItem item) {
    return {
      'itemId': item.id,
      'title': item.title,
      'source': item.source,
      'publicationDate': item.publicationDate.toIso8601String(),
      'category': item.category,
      'tags': item.tags,
      'relatedSubjects': item.relatedSubjects,
      'summary': item.summary,
      'contentType': 'current_affairs',
    };
  }
}
