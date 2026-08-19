import 'entities/dictionary_entry.dart';

/// Base exception class for all dictionary errors in TITAN Reader.
///
/// Raw transport and storage errors are wrapped into these typed
/// exceptions so callers never see raw HTTP or IO details.
abstract class DictionaryException implements Exception {
  final String message;
  final Object? cause;

  const DictionaryException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

/// The requested word has no entry in any available dictionary source.
class DictionaryNotFoundException extends DictionaryException {
  final String word;

  const DictionaryNotFoundException(this.word, [Object? cause])
      : super('No dictionary entry found for "$word".', cause);
}

/// Lookup failed because no source is reachable and the word is not in the
/// local dictionary (offline with no cached/bundled entry).
class DictionaryOfflineUnavailableException extends DictionaryException {
  final String word;

  const DictionaryOfflineUnavailableException(this.word, [Object? cause])
      : super('"$word" is not available offline.', cause);
}

/// A dictionary source returned data that could not be parsed.
class DictionaryParseFailureException extends DictionaryException {
  const DictionaryParseFailureException(super.message, [super.cause]);
}

/// A dictionary source failed to respond (network error, timeout, HTTP
/// failure). Details of the underlying transport error stay in [cause].
class DictionarySourceException extends DictionaryException {
  const DictionarySourceException(super.message, [super.cause]);
}

/// Persisting or reading cached dictionary data failed.
class DictionaryStorageFailureException extends DictionaryException {
  const DictionaryStorageFailureException(super.message, [super.cause]);
}

/// Outcome of a dictionary lookup.
///
/// Lookups model every required UI state explicitly instead of throwing:
/// found entries, words missing from the local dictionary (with a flag
/// distinguishing "offline unavailable" from plain "not found") and typed
/// failures.
sealed class DictionaryLookupResult {
  const DictionaryLookupResult();

  /// The word this lookup was performed for (normalized).
  String get word;
}

/// Lookup succeeded with a source-backed entry.
class DictionaryLookupFound extends DictionaryLookupResult {
  @override
  final String word;

  final DictionaryEntry entry;

  /// Whether the entry came from the bundled/local dictionary rather than
  /// a remote source or cache.
  final bool fromLocalSource;

  const DictionaryLookupFound({
    required this.word,
    required this.entry,
    required this.fromLocalSource,
  });

  @override
  String toString() => 'DictionaryLookupFound("$word")';
}

/// The word is not in the local dictionary.
///
/// [offline] is true when no remote lookup could even be attempted (remote
/// disabled or no connectivity), so the UI can show "Not available offline"
/// instead of a plain not-found message.
class DictionaryLookupNotFound extends DictionaryLookupResult {
  @override
  final String word;

  final bool offline;

  const DictionaryLookupNotFound(this.word, {this.offline = false});

  @override
  String toString() => 'DictionaryLookupNotFound("$word", offline: $offline)';
}

/// Lookup failed with a typed dictionary error.
class DictionaryLookupFailure extends DictionaryLookupResult {
  @override
  final String word;

  final DictionaryException error;

  const DictionaryLookupFailure(this.word, this.error);

  @override
  String toString() => 'DictionaryLookupFailure("$word", $error)';
}
