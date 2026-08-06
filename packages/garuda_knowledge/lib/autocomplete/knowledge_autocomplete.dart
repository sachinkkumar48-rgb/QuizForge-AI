import '../indexing/knowledge_index.dart';
import '../text/knowledge_normalizer.dart';

/// Fast prefix-matching autocomplete engine for GARUDA search inputs.
class KnowledgeAutocomplete {
  final KnowledgeIndex index;
  final KnowledgeNormalizer normalizer;

  KnowledgeAutocomplete({
    required this.index,
    KnowledgeNormalizer? normalizer,
  }) : normalizer = normalizer ?? KnowledgeNormalizer();

  /// Returns auto-complete suggestions matching the given prefix.
  List<String> autocomplete(String prefix, {int limit = 10}) {
    if (prefix.trim().isEmpty) return const [];
    final lowerPrefix = prefix.toLowerCase().trim();
    final matches = <String>{};

    for (final obj in index.storedObjects.values) {
      // Title
      if (obj.title.toLowerCase().startsWith(lowerPrefix)) {
        matches.add(obj.title);
      }

      // Aliases
      final aliases = obj.metadata.customAttributes['aliases'];
      if (aliases is List) {
        for (final alias in aliases) {
          final aStr = alias.toString();
          if (aStr.toLowerCase().startsWith(lowerPrefix)) {
            matches.add(aStr);
          }
        }
      }

      // Article Numbers
      final art = obj.metadata.customAttributes['article_number'];
      if (art != null) {
        final artStr = 'Article ${art.toString()}';
        if (artStr.toLowerCase().startsWith(lowerPrefix) ||
            art.toString().toLowerCase().startsWith(lowerPrefix)) {
          matches.add(artStr);
        }
      }

      // Case Names
      final caseName = obj.metadata.customAttributes['case_name'];
      if (caseName != null && caseName.toString().toLowerCase().startsWith(lowerPrefix)) {
        matches.add(caseName.toString());
      }

      // Acts
      final act = obj.metadata.customAttributes['act'];
      if (act != null && act.toString().toLowerCase().startsWith(lowerPrefix)) {
        matches.add(act.toString());
      }

      // Committees
      final comm = obj.metadata.customAttributes['committee'];
      if (comm != null && comm.toString().toLowerCase().startsWith(lowerPrefix)) {
        matches.add(comm.toString());
      }

      // Reports
      final report = obj.metadata.customAttributes['report'];
      if (report != null && report.toString().toLowerCase().startsWith(lowerPrefix)) {
        matches.add(report.toString());
      }

      // PYQ IDs
      final pyq = obj.metadata.customAttributes['pyq_id'];
      if (pyq != null && pyq.toString().toLowerCase().startsWith(lowerPrefix)) {
        matches.add(pyq.toString());
      }

      if (matches.length >= limit) break;
    }

    return matches.take(limit).toList();
  }
}
