import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dictionary_errors.dart';
import '../domain/entities/ai_reading_models.dart';
import '../domain/entities/ai_reading_task.dart';
import '../domain/entities/grammar_issue.dart';
import '../domain/entities/unified_text_context.dart';
import '../domain/entities/vocabulary_word.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/dictionary_panel.dart';
import '../widgets/grammar_panel.dart';
import 'ai_reading_service.dart';
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

  /// Creates a validated [AIReadingRequest] from [textContext].
  AIReadingRequest createAIRequest(
    UnifiedTextContext textContext, {
    required AIReadingTask task,
    AIContextScope contextScope = AIContextScope.selection,
    String? userQuestion,
    AISummaryLength summaryLength = AISummaryLength.medium,
    AISimplifyLevel simplifyLevel = AISimplifyLevel.simple,
    String? targetLanguage,
    String? customInstruction,
  }) {
    return textContext.toAIReadingRequest(
      task: task,
      contextScope: contextScope,
      userQuestion: userQuestion,
      summaryLength: summaryLength,
      simplifyLevel: simplifyLevel,
      targetLanguage: targetLanguage,
      customInstruction: customInstruction,
    );
  }

  /// Executes an AI reading task on [aiService] using [textContext].
  Future<AIReadingResponse> executeAITask(
    AIReadingService aiService,
    UnifiedTextContext textContext, {
    required AIReadingTask task,
    AIContextScope contextScope = AIContextScope.selection,
    String? userQuestion,
    AISummaryLength summaryLength = AISummaryLength.medium,
    AISimplifyLevel simplifyLevel = AISimplifyLevel.simple,
    String? targetLanguage,
    String? customInstruction,
  }) async {
    final request = createAIRequest(
      textContext,
      task: task,
      contextScope: contextScope,
      userQuestion: userQuestion,
      summaryLength: summaryLength,
      simplifyLevel: simplifyLevel,
      targetLanguage: targetLanguage,
      customInstruction: customInstruction,
    );
    return aiService.processTask(request);
  }

  /// Opens the existing Reader AI Assistant bottom sheet panel for [textContext].
  void showAIUI(
    BuildContext context,
    UnifiedTextContext textContext, {
    AIReadingTask initialTask = AIReadingTask.explain,
    void Function(int pageNumber)? onNavigateToPage,
  }) {
    if (textContext.selectedText.trim().isEmpty) return;

    showAIAssistantPanel(
      context,
      text: textContext.selectedText,
      initialTask: initialTask,
      documentId: textContext.documentId,
      documentName: textContext.documentName,
      pageNumber: textContext.pageNumber,
      onNavigateToPage: onNavigateToPage,
    );
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
