import 'package:meta/meta.dart';

/// Learning status of a saved vocabulary word.
enum VocabularyMasteryStatus {
  /// Saved but not studied yet. Initial status for new words.
  isNew('New'),

  /// Actively being learned.
  learning('Learning'),

  /// Recognized reliably.
  known('Known'),

  /// Fully internalized.
  mastered('Mastered');

  const VocabularyMasteryStatus(this.label);

  /// User-visible label.
  final String label;

  /// Parses a persisted status label; unknown values fall back to [isNew].
  static VocabularyMasteryStatus fromLabel(String? label) {
    for (final status in VocabularyMasteryStatus.values) {
      if (status.name == label || status.label == label) return status;
    }
    return VocabularyMasteryStatus.isNew;
  }
}

/// A word saved into the user's personal vocabulary.
///
/// Vocabulary words are user-owned data: the dictionary reference may
/// change between bundled-dictionary versions, so the word keeps its own
/// personal meaning/note and a snapshot of where it was encountered.
@immutable
class VocabularyWord {
  /// Stable unique identifier.
  final String id;

  /// Display form of the word as saved.
  final String word;

  /// Normalized lookup key shared with the dictionary.
  final String normalizedWord;

  /// Identifier of the dictionary source the word was saved from, when a
  /// dictionary entry was available at save time.
  final String? dictionarySourceId;

  /// The user's own short meaning. Never overwrites dictionary definitions.
  final String personalMeaning;

  /// Free-form personal note.
  final String personalNote;

  /// Document the word was encountered in, when saved from the Reader.
  final String? sourceDocumentId;

  /// Display name of the source document at save time.
  final String? sourceDocumentName;

  /// 1-based page of the source document where the word was selected.
  final int? sourcePage;

  /// Exact text selected when the word was saved.
  final String? selectedText;

  /// Learning status; defaults to [VocabularyMasteryStatus.isNew].
  final VocabularyMasteryStatus status;

  /// Creation timestamp. Injected by callers for deterministic tests.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.normalizedWord,
    required this.createdAt,
    required this.updatedAt,
    this.dictionarySourceId,
    this.personalMeaning = '',
    this.personalNote = '',
    this.sourceDocumentId,
    this.sourceDocumentName,
    this.sourcePage,
    this.selectedText,
    this.status = VocabularyMasteryStatus.isNew,
  });

  /// Whether the word remembers enough source context to jump back to the
  /// originating document and page.
  bool get hasNavigableSource => sourceDocumentId != null && sourcePage != null;

  /// Whether [query] matches word, personal meaning, personal note or the
  /// source document name, case-insensitively. Empty queries match nothing.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return word.toLowerCase().contains(needle) ||
        personalMeaning.toLowerCase().contains(needle) ||
        personalNote.toLowerCase().contains(needle) ||
        (sourceDocumentName?.toLowerCase().contains(needle) ?? false);
  }

  /// Returns a copy with the given fields replaced.
  VocabularyWord copyWith({
    String? personalMeaning,
    String? personalNote,
    VocabularyMasteryStatus? status,
    DateTime? updatedAt,
  }) {
    return VocabularyWord(
      id: id,
      word: word,
      normalizedWord: normalizedWord,
      dictionarySourceId: dictionarySourceId,
      personalMeaning: personalMeaning ?? this.personalMeaning,
      personalNote: personalNote ?? this.personalNote,
      sourceDocumentId: sourceDocumentId,
      sourceDocumentName: sourceDocumentName,
      sourcePage: sourcePage,
      selectedText: selectedText,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'word': word,
        'normalizedWord': normalizedWord,
        'dictionarySourceId': dictionarySourceId,
        'personalMeaning': personalMeaning,
        'personalNote': personalNote,
        'sourceDocumentId': sourceDocumentId,
        'sourceDocumentName': sourceDocumentName,
        'sourcePage': sourcePage,
        'selectedText': selectedText,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserializes a [VocabularyWord]; throws [FormatException] on malformed
  /// required fields and falls back gracefully on optional ones.
  factory VocabularyWord.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final word = json['word'];
    final normalizedWord = json['normalizedWord'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    if (id is! String ||
        word is! String ||
        normalizedWord is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException(
          'VocabularyWord JSON requires id, word, normalizedWord, createdAt '
          'and updatedAt fields.');
    }
    final dictionarySourceId = json['dictionarySourceId'];
    final personalMeaning = json['personalMeaning'];
    final personalNote = json['personalNote'];
    final sourceDocumentId = json['sourceDocumentId'];
    final sourceDocumentName = json['sourceDocumentName'];
    final sourcePage = json['sourcePage'];
    final selectedText = json['selectedText'];
    final status = json['status'];
    return VocabularyWord(
      id: id,
      word: word,
      normalizedWord: normalizedWord,
      dictionarySourceId:
          dictionarySourceId is String ? dictionarySourceId : null,
      personalMeaning: personalMeaning is String ? personalMeaning : '',
      personalNote: personalNote is String ? personalNote : '',
      sourceDocumentId: sourceDocumentId is String ? sourceDocumentId : null,
      sourceDocumentName:
          sourceDocumentName is String ? sourceDocumentName : null,
      sourcePage: sourcePage is int ? sourcePage : null,
      selectedText: selectedText is String ? selectedText : null,
      status:
          VocabularyMasteryStatus.fromLabel(status is String ? status : null),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyWord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          word == other.word &&
          normalizedWord == other.normalizedWord &&
          dictionarySourceId == other.dictionarySourceId &&
          personalMeaning == other.personalMeaning &&
          personalNote == other.personalNote &&
          sourceDocumentId == other.sourceDocumentId &&
          sourceDocumentName == other.sourceDocumentName &&
          sourcePage == other.sourcePage &&
          selectedText == other.selectedText &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
      id,
      word,
      normalizedWord,
      dictionarySourceId,
      personalMeaning,
      personalNote,
      sourceDocumentId,
      sourceDocumentName,
      sourcePage,
      selectedText,
      status,
      createdAt,
      updatedAt);

  @override
  String toString() =>
      'VocabularyWord(id: $id, "$word", status: ${status.name})';
}
