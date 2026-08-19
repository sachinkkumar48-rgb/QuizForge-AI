import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/dictionary_errors.dart';
import '../domain/entities/dictionary_entry.dart';

/// HTTP response tuple returned by the injectable fetch function.
class RemoteDictionaryHttpResponse {
  final int statusCode;
  final String body;

  const RemoteDictionaryHttpResponse(this.statusCode, this.body);
}

/// Signature of the transport used by remote dictionary sources; injectable
/// so tests never touch the network.
typedef RemoteDictionaryFetch = Future<RemoteDictionaryHttpResponse> Function(
    Uri uri);

/// Contract for optional online dictionary sources.
///
/// Remote sources are only consulted when the local dictionary has no
/// entry and the user has enabled online lookup. They must transmit the
/// word itself and nothing else (no PDF content, no notes).
abstract class RemoteDictionarySource {
  /// Stable identifier recorded on cached entries.
  String get sourceId;

  /// Looks up [normalizedWord]. Returns null when the source has no entry.
  ///
  /// Throws [DictionarySourceException] on transport failures and
  /// [DictionaryParseFailureException] on malformed responses.
  Future<DictionaryEntry?> lookup(String normalizedWord);
}

/// Remote source backed by the free dictionaryapi.dev service
/// (WordNet-derived data, MIT licensed).
///
/// Privacy: the request contains only the requested word in the URL path.
class DictionaryApiDevSource implements RemoteDictionarySource {
  DictionaryApiDevSource({
    RemoteDictionaryFetch? fetch,
    this.baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en',
    this.timeout = const Duration(seconds: 10),
  }) : _fetch = fetch ?? _defaultFetch;

  /// Source identifier stored with cached entries.
  static const String id = 'remote:dictionaryapi.dev';

  final String baseUrl;
  final Duration timeout;
  final RemoteDictionaryFetch _fetch;

  static const Duration _defaultTimeout = Duration(seconds: 10);

  static Future<RemoteDictionaryHttpResponse> _defaultFetch(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(_defaultTimeout);
      final response = await request.close().timeout(_defaultTimeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_defaultTimeout);
      return RemoteDictionaryHttpResponse(response.statusCode, body);
    } on TimeoutException catch (error) {
      throw DictionarySourceException(
          'Remote dictionary lookup timed out.', error);
    } on SocketException catch (error) {
      throw DictionarySourceException(
          'Remote dictionary is unreachable.', error);
    } on HttpException catch (error) {
      throw DictionarySourceException(
          'Remote dictionary request failed.', error);
    } finally {
      client.close(force: true);
    }
  }

  @override
  String get sourceId => id;

  @override
  Future<DictionaryEntry?> lookup(String normalizedWord) async {
    final uri = Uri.parse('$baseUrl/${Uri.encodeComponent(normalizedWord)}');
    final response = await _fetch(uri);
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DictionarySourceException(
          'Remote dictionary returned status ${response.statusCode}.');
    }
    try {
      return _parse(normalizedWord, response.body);
    } on FormatException catch (error) {
      throw DictionaryParseFailureException(
          'Remote dictionary response could not be parsed.', error);
    }
  }

  DictionaryEntry? _parse(String normalizedWord, String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map<String, Object?>) return null;

    final displayWord = (first['word'] as String?) ?? normalizedWord;
    String? phonetic = first['phonetic'] as String?;
    if (phonetic == null) {
      final phonetics = first['phonetics'];
      if (phonetics is List) {
        for (final item in phonetics.whereType<Map<String, Object?>>()) {
          final text = item['text'];
          if (text is String && text.isNotEmpty) {
            phonetic = text;
            break;
          }
        }
      }
    }
    final origin = first['origin'];

    final senses = <DictionarySense>[];
    final meanings = first['meanings'];
    if (meanings is List) {
      for (final meaning in meanings.whereType<Map<String, Object?>>()) {
        final pos = meaning['partOfSpeech'];
        if (pos is! String) continue;
        final definitions = <String>[];
        final examples = <String>[];
        final synonyms = <String>{};
        final antonyms = <String>{};
        final rawDefinitions = meaning['definitions'];
        if (rawDefinitions is List) {
          for (final item in rawDefinitions.whereType<Map<String, Object?>>()) {
            final definition = item['definition'];
            if (definition is String && definition.isNotEmpty) {
              definitions.add(definition);
            }
            final example = item['example'];
            if (example is String && example.isNotEmpty) {
              examples.add(example);
            }
            synonyms.addAll(_strings(item['synonyms']));
            antonyms.addAll(_strings(item['antonyms']));
          }
        }
        synonyms.addAll(_strings(meaning['synonyms']));
        antonyms.addAll(_strings(meaning['antonyms']));
        if (definitions.isEmpty) continue;
        senses.add(DictionarySense(
          partOfSpeech: pos,
          definitions: List.unmodifiable(definitions),
          examples: List.unmodifiable(examples),
          synonyms: List.unmodifiable(synonyms),
          antonyms: List.unmodifiable(antonyms),
        ));
      }
    }
    if (senses.isEmpty) return null;
    return DictionaryEntry(
      word: displayWord,
      normalizedWord: normalizedWord,
      phonetic: phonetic,
      wordOrigin: origin is String && origin.isNotEmpty ? origin : null,
      senses: List.unmodifiable(senses),
      source: const DictionarySourceInfo(
        id: id,
        attribution: 'dictionaryapi.dev (free dictionary API)',
      ),
    );
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
