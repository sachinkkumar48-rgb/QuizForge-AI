import 'package:meta/meta.dart';

/// One sense group of a dictionary entry, grouped by part of speech.
///
/// Every field is source-backed: nothing here is ever synthesized by the
/// application. Missing data stays absent instead of being fabricated.
@immutable
class DictionarySense {
  /// Part of speech label exactly as provided by the lexical source
  /// (e.g. `noun`, `verb`, `adjective`, `adverb`).
  final String partOfSpeech;

  /// Numbered definitions, in source order. May be empty.
  final List<String> definitions;

  /// Usage examples quoted from the lexical source. May be empty.
  final List<String> examples;

  /// Source-backed synonyms. May be empty.
  final List<String> synonyms;

  /// Source-backed antonyms. May be empty.
  final List<String> antonyms;

  const DictionarySense({
    required this.partOfSpeech,
    this.definitions = const [],
    this.examples = const [],
    this.synonyms = const [],
    this.antonyms = const [],
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'partOfSpeech': partOfSpeech,
        'definitions': definitions,
        'examples': examples,
        'synonyms': synonyms,
        'antonyms': antonyms,
      };

  /// Deserializes a [DictionarySense]; tolerates missing optional lists.
  factory DictionarySense.fromJson(Map<String, Object?> json) {
    final partOfSpeech = json['partOfSpeech'];
    if (partOfSpeech is! String) {
      throw const FormatException(
          'DictionarySense JSON requires a partOfSpeech string.');
    }
    return DictionarySense(
      partOfSpeech: partOfSpeech,
      definitions: _stringList(json['definitions']),
      examples: _stringList(json['examples']),
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
    );
  }

  static List<String> _stringList(Object? value) =>
      value is List ? List.unmodifiable(value.whereType<String>()) : const [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionarySense &&
          runtimeType == other.runtimeType &&
          partOfSpeech == other.partOfSpeech &&
          _listEquals(definitions, other.definitions) &&
          _listEquals(examples, other.examples) &&
          _listEquals(synonyms, other.synonyms) &&
          _listEquals(antonyms, other.antonyms);

  @override
  int get hashCode => Object.hash(
      partOfSpeech,
      Object.hashAll(definitions),
      Object.hashAll(examples),
      Object.hashAll(synonyms),
      Object.hashAll(antonyms));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'DictionarySense($partOfSpeech, ${definitions.length} definitions)';
}

/// Identification of the lexical source behind a [DictionaryEntry].
///
/// Entries never mix sources; the origin is always attributable so the UI
/// can display provenance and licensing information.
@immutable
class DictionarySourceInfo {
  /// Stable source identifier (e.g. `wordnet-3.0`, `remote:dictionaryapi`).
  final String id;

  /// Human-readable attribution text.
  final String attribution;

  const DictionarySourceInfo({required this.id, required this.attribution});

  Map<String, Object?> toJson() =>
      <String, Object?>{'id': id, 'attribution': attribution};

  factory DictionarySourceInfo.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final attribution = json['attribution'];
    if (id is! String || attribution is! String) {
      throw const FormatException(
          'DictionarySourceInfo JSON requires id and attribution strings.');
    }
    return DictionarySourceInfo(id: id, attribution: attribution);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionarySourceInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          attribution == other.attribution;

  @override
  int get hashCode => Object.hash(id, attribution);

  @override
  String toString() => 'DictionarySourceInfo($id)';
}

/// A source-backed dictionary entry for one headword.
///
/// Deliberately independent of any JSON wire format, HTTP response model,
/// storage schema or dictionary package; serialization lives in the
/// repositories (see `fromJson`/`toJson` convenience constructors).
@immutable
class DictionaryEntry {
  /// The headword in its display form.
  final String word;

  /// Normalized lookup key (lowercase, trimmed, surrounding punctuation
  /// stripped).
  final String normalizedWord;

  /// IPA/phonetic transcription when the source provides one. WordNet does
  /// not; the field stays null instead of being faked.
  final String? phonetic;

  /// Sense groups in display order. Never empty.
  final List<DictionarySense> senses;

  /// Etymology/word origin when legally provided by the source.
  final String? wordOrigin;

  /// Where this entry came from.
  final DictionarySourceInfo source;

  const DictionaryEntry({
    required this.word,
    required this.normalizedWord,
    required this.senses,
    required this.source,
    this.phonetic,
    this.wordOrigin,
  }) : assert(senses.length > 0, 'DictionaryEntry requires at least one sense');

  /// Every part of speech covered by this entry, in display order.
  List<String> get partsOfSpeech =>
      List.unmodifiable([for (final sense in senses) sense.partOfSpeech]);

  Map<String, Object?> toJson() => <String, Object?>{
        'word': word,
        'normalizedWord': normalizedWord,
        'phonetic': phonetic,
        'wordOrigin': wordOrigin,
        'source': source.toJson(),
        'senses': [for (final sense in senses) sense.toJson()],
      };

  /// Deserializes a [DictionaryEntry]; throws [FormatException] on
  /// malformed required fields.
  factory DictionaryEntry.fromJson(Map<String, Object?> json) {
    final word = json['word'];
    final normalizedWord = json['normalizedWord'];
    final source = json['source'];
    final senses = json['senses'];
    if (word is! String ||
        normalizedWord is! String ||
        source is! Map<String, Object?> ||
        senses is! List ||
        senses.isEmpty) {
      throw const FormatException(
          'DictionaryEntry JSON requires word, normalizedWord, source and '
          'a non-empty senses list.');
    }
    final phonetic = json['phonetic'];
    final wordOrigin = json['wordOrigin'];
    return DictionaryEntry(
      word: word,
      normalizedWord: normalizedWord,
      phonetic: phonetic is String ? phonetic : null,
      wordOrigin: wordOrigin is String ? wordOrigin : null,
      source: DictionarySourceInfo.fromJson(source),
      senses: List.unmodifiable(senses
          .whereType<Map<String, Object?>>()
          .map(DictionarySense.fromJson)),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryEntry &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          normalizedWord == other.normalizedWord &&
          phonetic == other.phonetic &&
          wordOrigin == other.wordOrigin &&
          source == other.source &&
          senses.length == other.senses.length &&
          [
            for (var i = 0; i < senses.length; i++)
              senses[i] == other.senses[i],
          ].every((equal) => equal);

  @override
  int get hashCode => Object.hash(word, normalizedWord, phonetic, wordOrigin,
      source, Object.hashAll(senses));

  @override
  String toString() =>
      'DictionaryEntry("$word", ${senses.length} senses, source: ${source.id})';
}
