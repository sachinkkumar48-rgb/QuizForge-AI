import 'package:meta/meta.dart';

/// One recorded dictionary lookup, most recent first in storage.
@immutable
class RecentDictionaryLookup {
  /// Normalized word that was looked up.
  final String word;

  /// When the lookup happened.
  final DateTime at;

  const RecentDictionaryLookup({required this.word, required this.at});

  Map<String, Object?> toJson() => <String, Object?>{
        'word': word,
        'at': at.toIso8601String(),
      };

  /// Deserializes a [RecentDictionaryLookup]; throws [FormatException] on
  /// malformed required fields.
  factory RecentDictionaryLookup.fromJson(Map<String, Object?> json) {
    final word = json['word'];
    final at = json['at'];
    if (word is! String || at is! String) {
      throw const FormatException(
          'RecentDictionaryLookup JSON requires word and at fields.');
    }
    return RecentDictionaryLookup(word: word, at: DateTime.parse(at));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentDictionaryLookup &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          at == other.at;

  @override
  int get hashCode => Object.hash(word, at);

  @override
  String toString() => 'RecentDictionaryLookup("$word", $at)';
}
