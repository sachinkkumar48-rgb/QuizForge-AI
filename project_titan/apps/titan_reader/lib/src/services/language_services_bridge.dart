import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dictionary_errors.dart';
import '../domain/entities/grammar_issue.dart';
import '../domain/entities/unified_text_context.dart';
import '../domain/entities/vocabulary_word.dart';
import '../widgets/dictionary_panel.dart';
import '../widgets/grammar_panel.dart';
import 'dictionary_service.dart';
import 'grammar_service.dart';
import 'vocabulary_service.dart';

/// Application coordinator bridging [UnifiedTextContext] selections (whether
/// originating from native PDF glyphs or on-device OCR) to TITAN Reader's
/// existing language services (Dictionary, Grammar, Vocabulary).
class LanguageServicesBridge {
  const LanguageServicesBridge();

  /// Performs a dictionary lookup for the word in [textContext].
  ///
  /// Returns null or [DictionaryLookupNotFound] if the selection contains
  /// multiple words or whitespace.
  Future<DictionaryLookupResult?> lookupInDictionary(
    DictionaryService dictionaryService,
    UnifiedTextContext textContext,
  ) async {
    final word = textContext.normalizedWord;
    if (word == null || word.isEmpty) {
      return DictionaryLookupNotFound(textContext.selectedText);
    }
    return dictionaryService.lookup(word);
  }

  /// Opens the existing Reader dictionary modal panel for [textContext].
  void showDictionaryUI(
    BuildContext context,
    UnifiedTextContext textContext,
  ) {
    final word = textContext.normalizedWord;
    if (word == null || word.isEmpty) return;

    showDictionaryPanel(
      context,
      word: word,
      documentId: textContext.documentId,
      documentName: textContext.documentName,
      pageNumber: textContext.pageNumber,
      selectedText: textContext.selectedText,
    );
  }

  /// Performs grammar and spelling analysis over the text in [textContext].
  Future<({GrammarCheckResult result, GrammarRemoteOutcome remote})>
      checkGrammar(
    GrammarService grammarService,
    UnifiedTextContext textContext,
  ) async {
    return grammarService.checkText(textContext.selectedText);
  }

  /// Opens the existing Reader grammar modal panel for [textContext].
  void showGrammarUI(
    BuildContext context,
    UnifiedTextContext textContext,
  ) {
    if (textContext.selectedText.trim().isEmpty) return;

    showGrammarPanel(
      context,
      text: textContext.selectedText,
      documentId: textContext.documentId,
      documentName: textContext.documentName,
      pageNumber: textContext.pageNumber,
    );
  }

  /// Saves the selected word from [textContext] directly into the user's Vocabulary.
  Future<VocabularyWord?> saveToVocabulary(
    VocabularyService vocabularyService,
    UnifiedTextContext textContext, {
    String? personalMeaning,
    String? personalNote,
  }) async {
    final word = textContext.normalizedWord;
    if (word == null || word.isEmpty) return null;

    await vocabularyService.ensureLoaded();
    final saved = await vocabularyService.saveWord(
      rawWord: word,
      at: DateTime.now(),
      sourceDocumentId: textContext.documentId,
      sourceDocumentName: textContext.documentName,
      sourcePage: textContext.pageNumber,
      selectedText: textContext.selectedText,
    );

    if (personalMeaning != null || personalNote != null) {
      return vocabularyService.updateWord(
        wordId: saved.id,
        at: DateTime.now(),
        personalMeaning: personalMeaning,
        personalNote: personalNote,
      );
    }

    return saved;
  }

  /// Copies the text in [textContext] safely to the system clipboard without logging.
  Future<bool> copyToClipboard(UnifiedTextContext? textContext) async {
    if (textContext == null || textContext.selectedText.isEmpty) return false;
    try {
      await Clipboard.setData(ClipboardData(text: textContext.selectedText));
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Provider exposing the active [UnifiedTextContext] across the Reader screen.
final activeTextContextProvider =
    StateProvider<UnifiedTextContext?>((ref) => null);

/// Provider exposing the singleton [LanguageServicesBridge] coordinator.
final languageServicesBridgeProvider = Provider<LanguageServicesBridge>((ref) {
  return const LanguageServicesBridge();
});
