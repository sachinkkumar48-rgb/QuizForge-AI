import 'package:meta/meta.dart';

/// Domain synonym dictionary for Indian legal and constitutional terminology.
@immutable
class KnowledgeSynonymDictionary {
  final Map<String, Set<String>> _synonymGroups;

  KnowledgeSynonymDictionary({Map<String, Set<String>>? customSynonyms})
      : _synonymGroups = customSynonyms ?? _defaultSynonyms;

  static final Map<String, Set<String>> _defaultSynonyms = {
    'fr': {'fundamental rights', 'part iii', 'rights'},
    'dpsp': {'directive principles', 'part iv', 'state policy'},
    'sc': {'supreme court', 'apex court', 'highest court'},
    'hc': {'high court'},
    'cj': {'chief justice', 'cji'},
    'art': {'article', 'provision'},
    'pyq': {'previous year question', 'past question'},
    'preamble': {'sovereign', 'socialist', 'secular', 'democratic', 'republic'},
    'basic structure': {'kesavananda bharti', 'basic features'},
  };

  /// Expands a term into its known domain synonyms.
  Set<String> expand(String term) {
    final lower = term.toLowerCase().trim();
    final results = <String>{lower};

    for (final entry in _synonymGroups.entries) {
      if (entry.key == lower || entry.value.contains(lower)) {
        results.add(entry.key);
        results.addAll(entry.value);
      }
    }
    return results;
  }
}
