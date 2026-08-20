# TITAN Reader — Feature Matrix

Status: ✅ shipped · 🚧 in progress · ⏳ planned

## Phase 1 — Reader foundation

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| App shell + bootstrap (storage, ProviderScope) | ✅ | `main.dart`, `app.dart` | `app_shell_test.dart` |
| Navigation (go_router, error handling) | ✅ | `navigation/reader_router.dart` | `app_shell_test.dart` |
| Light/dark theme | ✅ | `theme/reader_theme.dart` | analyze + app boot |
| Library list with metadata | ✅ | `screens/library_screen.dart`, `widgets/document_card.dart` | `library_screen_test.dart` |
| PDF import with validation (titan_pdf rules) | ✅ | `services/library_service.dart` | `library_service_test.dart` |
| Open + render PDF (pdfrx behind abstraction) | ✅ | `pdf/pdfrx_pdf_engine.dart` | `reader_screen_test.dart` (fake engine) |
| Continuous scrolling | ✅ | pdfrx default viewer mode | manual/device |
| Page navigation | ✅ | `reader_screen.dart` slider + engine events | `reader_screen_test.dart` |
| Page number display | ✅ | reader bottom bar | `reader_screen_test.dart` |
| Page slider | ✅ | reader bottom bar | `reader_screen_test.dart` |
| Zoom in/out | ✅ | handle `zoomIn`/`zoomOut` | `reader_screen_test.dart` |
| Fit width / fit page | ✅ | view-options menu → `applyFitMode` | `reader_screen_test.dart` |
| Rotation (presentation-level) | ✅ | view-options menu → `rotateClockwise` | `reader_screen_test.dart` |
| Recent documents shelf | ✅ | `_RecentShelf` in library screen | `library_screen_test.dart` |
| Reading history (ordering, dedup, cap) | ✅ | `services/reading_history_service.dart` | `reading_history_service_test.dart` |
| Last reading position (restore + persist) | ✅ | `reader_screen.dart` + position repo | `reader_screen_test.dart` |
| Document metadata (size, added, page count) | ✅ | `ReaderDocument` entity | `entities_test.dart`, `repositories_test.dart` |
| Basic text search | ✅ | `widgets/document_search_bar.dart` | `document_search_bar_test.dart` |
| Search result navigation (prev/next/list) | ✅ | search bar + handle match APIs | `document_search_bar_test.dart` |
| Favorites + removal (cascade) | ✅ | library screen + service | `library_screen_test.dart`, `library_service_test.dart` |

## Phase 2 — Annotations, bookmarks & notes

All Phase 2 data is **Reader-managed**: persisted in TITAN storage
(`titan.reader.*` namespaces), rendered as engine overlays. It is NOT
embedded into the PDF file (pdfrx 2.4.7 cannot create PDF-native
annotations) — see PDF_ENGINE.md.

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| Text selection capture (text + geometry) | ✅ | `PdfViewerHandle.captureTextSelection` | `reader_phase2_test.dart` |
| Highlight (5 colors, add/remove/recolor) | ✅ | `annotation_service.dart`, overlays | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| Underline (add/remove) | ✅ | same pipeline, `PdfOverlayStyle.underline` | `reader_phase2_test.dart` |
| Strikethrough (add/remove) | ✅ | same pipeline, `PdfOverlayStyle.strikethrough` | `reader_phase2_test.dart` |
| Annotation persistence + restore after restart | ✅ | `titan.reader.annotations` namespace | `reader_phase2_test.dart` (restart test) |
| Overlay rendering stable across zoom/resize | ✅ | normalized rects → `pagePaintCallbacks` | `phase2_entities_test.dart`, restart test |
| Selection context toolbar (Copy/Highlight/Underline/Strikethrough/Note) | ✅ | `customizeContextMenuItems` adapter hook | `reader_phase2_test.dart` |
| Dictionary / Grammar placeholders | ✅ | dictionary implemented in Phase 3; grammar still placeholder | `reader_phase2_test.dart` |
| Bookmarks (add/remove/edit/list/navigate) | ✅ | `bookmark_service.dart`, `bookmarks_panel.dart` | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| Bookmark persistence + restore after restart | ✅ | `titan.reader.bookmarks` namespace | `reader_phase2_test.dart` (restart test) |
| PDF-native outline reading + navigation | ✅ | `loadOutline`/`goToOutlineEntry` (never persisted) | `reader_phase2_test.dart` |
| Notes (add/edit/delete/search/navigate) | ✅ | `note_service.dart`, `notes_panel.dart` | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| Notes survive annotation deletion | ✅ | loose `annotationId` reference | `phase2_entities_test.dart` |
| Note persistence + restore after restart | ✅ | `titan.reader.notes` namespace | `reader_phase2_test.dart` (restart test) |
| Reader-scoped undo/redo | ✅ | `reader_undo_stack.dart` + service stacks | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| PDF-native annotation export/import | ⏳ | not supported by pdfrx 2.4.7; model designed for future mapping | — |

## Phase 3 — Dictionary & vocabulary

All dictionary content is **source-backed** (bundled WordNet 3.0; see
DICTIONARY.md for license/attribution). Nothing is AI-generated. Remote
lookup exists but is **off by default** (LOCAL_ONLY privacy).

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| Bundled offline dictionary (WordNet 3.0, 147,306 words) | ✅ | `assets/dictionary/`, `bundled_dictionary_data_source.dart` | `phase3_repositories_test.dart`, integration acceptance |
| Lazy shard loading + LRU cache (never whole dictionary in memory) | ✅ | `bundled_dictionary_data_source.dart` | `phase3_repositories_test.dart` |
| Word normalization (`"Ephemeral,"` → `ephemeral`) | ✅ | `domain/word_normalizer.dart` | `phase3_entities_test.dart` |
| Multi-word selection rejected for dictionary (§14) | ✅ | `reader_screen._singleSelectedWord` | `reader_phase2_test.dart` |
| Selection → Dictionary panel (definitions, POS, examples, synonyms/antonyms) | ✅ | `widgets/dictionary_panel.dart` | `dictionary_panel_test.dart`, integration W1 |
| Save Word from panel and from toolbar with source context | ✅ | `dictionary_panel._saveWord`, `reader_screen._saveWordFromSelection` | `dictionary_panel_test.dart`, integration W1/W2 |
| Explicit states: loading / success / not-found / offline / error | ✅ | `dictionary_panel._buildResult`, `_buildNotFound` | `dictionary_panel_test.dart` |
| Offline-unavailable state + opt-in online lookup switch | ✅ | `dictionary_panel._buildNotFound`, `remoteLookupEnabledProvider` | `dictionary_panel_test.dart`, integration W3 |
| Optional remote fallback (dictionaryapi.dev, word-only payload) | ✅ | `data/remote_dictionary_source.dart` | `phase3_services_test.dart` |
| Lookup cache with provenance (`dictionary:<word>`) | ✅ | `data/dictionary_cache_repository.dart` | `phase3_repositories_test.dart`, `phase3_services_test.dart` |
| Recent lookups (record, reopen, clear) | ✅ | `data/recent_lookup_repository.dart`, panel search home | `dictionary_panel_test.dart` |
| Prefix suggestions from headword index | ✅ | `prefixMatches` + binary search | `phase3_repositories_test.dart`, `dictionary_panel_test.dart` |
| My Vocabulary screen (list, search, sort, status filter) | ✅ | `screens/vocabulary_screen.dart` | `vocabulary_screen_test.dart` |
| Vocabulary statuses New/Learning/Known/Mastered (manual only) | ✅ | `VocabularyService.changeStatus` | `phase3_services_test.dart`, `vocabulary_screen_test.dart` |
| Personal meaning/note (never overwrites dictionary definitions) | ✅ | `vocabulary_word_editor_dialog.dart` | `vocabulary_screen_test.dart` |
| Source tracking + jump-back to document page | ✅ | `vocabulary_screen._openSource`, `/reader/:id?page=N` | `vocabulary_screen_test.dart`, integration W2 |
| Vocabulary persistence across restart | ✅ | `titan.reader.vocabulary` namespace | `phase3_services_test.dart`, integration W3 |
| Pronunciation / IPA / audio | ⏳ | WordNet ships no phonetics; never faked (§8) | — |

## Phase 4 — Grammar & spelling

All local grammar and spelling checks are **deterministic and offline-first**.
WordNet headwords are reused for spelling. Remote checking is **opt-in only**
and off by default. Applying suggestions creates **Reader-managed records**
without modifying the original PDF.

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| Bundled spelling engine (WordNet headword index, 147k words) | ✅ | `data/spell_checker.dart` | `phase4_engine_test.dart` |
| Edit-distance candidate generator (Damerau-Levenshtein d=1 then d=2) | ✅ | `data/spell_checker.dart` | `phase4_engine_test.dart` |
| Deterministic grammar rule engine (10 exact rules) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Repeated word detection (`rule.repeated-word`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Sentence capitalization check (`rule.sentence-capitalization`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Pronoun capitalization check (`rule.standalone-i`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Double space detection (`rule.double-space`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Doubled punctuation check (`rule.doubled-punctuation`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Punctuation spacing checks (`rule.punctuation-space-after/before`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Modal verb correction (`rule.modal-of`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| "Alot" split check (`rule.alot`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Article agreement check (`rule.article-agreement`) | ✅ | `data/local_rule_engine.dart` | `phase4_engine_test.dart` |
| Composite Local Engine (spelling suppression in rule spans) | ✅ | `data/grammar_engine.dart` | `phase4_engine_test.dart` |
| Optional remote source (LanguageTool HTTP, opt-in) | ✅ | `data/remote_grammar_source.dart` | `phase4_repositories_test.dart` |
| Offset-safe correction applier (`GrammarTextCorrection.apply`) | ✅ | `domain/grammar_text_correction.dart` | `phase4_entities_test.dart` |
| Grammar cache (`titan.reader.grammar.cache`, versioned key) | ✅ | `data/grammar_cache_repository.dart` | `phase4_repositories_test.dart`, `phase4_services_test.dart` |
| Reader-managed corrections persistence (`titan.reader.grammar.corrections`) | ✅ | `data/grammar_correction_repository.dart` | `phase4_repositories_test.dart`, `phase4_services_test.dart` |
| Selection toolbar integration (capture selection → Grammar action) | ✅ | `screens/reader_screen.dart` | `reader_phase4_test.dart` |
| Grammar panel UI (issues, suggestions, explanations, copy, dismiss, apply) | ✅ | `widgets/grammar_panel.dart` | `grammar_panel_test.dart` |
| Grammar → Dictionary / My Vocabulary integration | ✅ | `widgets/grammar_panel.dart` | `grammar_panel_test.dart`, `grammar_workflow_integration_test.dart` |

## Phase 5 — AI reading assistant

Multi-provider AI assistant architecture supporting local Ollama, OpenAI-compatible APIs, Google Gemini, and offline mocks. Features RAG-based context retrieval, prompt-injection defense fencing, response caching, conversation history, and flashcard generation.

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| Provider abstraction (`AIReadingProvider`) | ✅ | `data/ai_reading_provider.dart` | `phase5_ai_providers_test.dart` |
| Mock provider (offline deterministic) | ✅ | `data/mock_ai_reading_provider.dart` | `phase5_ai_providers_test.dart` |
| Ollama provider (local-first) | ✅ | `data/ollama_reading_provider.dart` | `phase5_ai_providers_test.dart` |
| OpenAI-compatible provider | ✅ | `data/openai_compatible_reading_provider.dart` | `phase5_ai_providers_test.dart` |
| Gemini REST provider | ✅ | `data/gemini_reading_provider.dart` | `phase5_ai_providers_test.dart` |
| RAG retrieval engine (TF-IDF passage search) | ✅ | `data/ai_retrieval_engine.dart` | `phase5_ai_retrieval_test.dart` |
| Prompt-injection defense fencing | ✅ | `domain/ai_reading_prompt_builder.dart` | `phase5_ai_entities_test.dart` |
| Response caching (`titan.reader.ai.cache`) | ✅ | `data/ai_cache_repository.dart` | `phase5_ai_services_test.dart` |
| Multi-turn conversations (`titan.reader.ai.conversations`) | ✅ | `data/ai_conversation_repository.dart` | `phase5_ai_services_test.dart` |
| Flashcard generation (`titan.reader.ai.flashcards`) | ✅ | `data/ai_flashcard_repository.dart` | `phase5_ai_services_test.dart` |
| Config repository (`titan.reader.ai.config`) | ✅ | `data/ai_config_repository.dart` | `phase5_ai_services_test.dart` |
| AI Assistant panel UI (task tabs, Q&A, copy, model badge) | ✅ | `widgets/ai_assistant_panel.dart` | `ai_assistant_panel_test.dart` |
| AI settings dialog (provider, URL, model, key) | ✅ | `widgets/ai_settings_dialog.dart` | `ai_assistant_panel_test.dart` |
| Selection context toolbar → AI action | ✅ | `screens/reader_screen.dart` | `reader_phase5_test.dart` |
| End-to-end AI workflows | ✅ | `test/integration/ai_workflow_integration_test.dart` | `ai_workflow_integration_test.dart` |

## Phase 6A — PDF document manipulation

Enterprise-grade, non-destructive PDF page mutations, document assembly, and structural manipulation powered by a pure Dart AST engine.

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| PDF AST Parser & Lexer | ✅ | `manipulation/ast/pdf_parser.dart` | `ast_parser_writer_test.dart` |
| PDF AST Serializer & Writer | ✅ | `manipulation/ast/pdf_writer.dart` | `ast_parser_writer_test.dart` |
| Merge PDFs | ✅ | `DefaultPdfManipulationEngine.merge` | `phase6a_manipulation_engine_test.dart`, `merge_pdfs_dialog_test.dart` |
| Split PDFs by ranges | ✅ | `DefaultPdfManipulationEngine.split` | `phase6a_manipulation_engine_test.dart` |
| Extract pages | ✅ | `DefaultPdfManipulationEngine.extractPages` | `phase6a_manipulation_engine_test.dart`, `organize_pages_dialog_test.dart` |
| Delete pages | ✅ | `DefaultPdfManipulationEngine.deletePages` | `phase6a_manipulation_engine_test.dart`, `organize_pages_dialog_test.dart` |
| Reorder pages | ✅ | `DefaultPdfManipulationEngine.reorderPages` | `phase6a_manipulation_engine_test.dart`, `organize_pages_dialog_test.dart` |
| Rotate pages (90/180/270°) | ✅ | `DefaultPdfManipulationEngine.rotatePages` | `phase6a_manipulation_engine_test.dart`, `organize_pages_dialog_test.dart` |
| Insert blank pages | ✅ | `DefaultPdfManipulationEngine.insertBlankPage` | `phase6a_manipulation_engine_test.dart`, `organize_pages_dialog_test.dart` |
| Insert pages from another PDF | ✅ | `DefaultPdfManipulationEngine.insertPagesFromPdf` | `phase6a_manipulation_engine_test.dart` |
| PDF Catalog `/PageLabels` | ✅ | `DefaultPdfManipulationEngine.setPageLabels` | `phase6a_manipulation_engine_test.dart` |
| Safe non-destructive output path generation | ✅ | `PdfDocumentManipulationService.generateSafeOutputPath` | `phase6a_manipulation_service_test.dart` |
| Pre/postflight output verification | ✅ | `PdfDocumentManipulationService` | `phase6a_manipulation_service_test.dart` |
| Merge PDFs Dialog UI | ✅ | `widgets/merge_pdfs_dialog.dart` | `merge_pdfs_dialog_test.dart` |
| Organize Pages Dialog UI | ✅ | `widgets/organize_pages_dialog.dart` | `organize_pages_dialog_test.dart` |
| End-to-end safe manipulation workflows | ✅ | `test/integration/phase6a_workflows_integration_test.dart` | `phase6a_workflows_integration_test.dart` |

## Phase 6A.1 — PDF engine hardening & compatibility audit

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| Corpus Category A–T Testing | ✅ | `test/manipulation/pdf_compatibility_corpus_test.dart` | `pdf_compatibility_corpus_test.dart` |
| Security Fuzzing & Malformed Resilience | ✅ | `test/manipulation/pdf_security_fuzzing_test.dart` | `pdf_security_fuzzing_test.dart` |
| Differential & Idempotence Roundtrips | ✅ | `test/manipulation/pdf_differential_validation_test.dart` | `pdf_differential_validation_test.dart` |
| Page Tree Attribute Inheritance Resolution | ✅ | `manipulation/ast/pdf_document_ast.dart` | `pdf_compatibility_corpus_test.dart` |
| Unicode UTF-16BE / Hex String Support | ✅ | `manipulation/ast/pdf_primitive.dart` | `pdf_compatibility_corpus_test.dart` |
| Zero-Page & Malformed Structure Safe Guard | ✅ | `manipulation/ast/pdf_parser.dart` | `pdf_security_fuzzing_test.dart` |
| Encrypted PDF Rejection Guard | ✅ | `manipulation/ast/pdf_parser.dart` | `pdf_compatibility_corpus_test.dart` |

## Phase 6B — PDF-native annotations

Full ISO 32000-1 compliant PDF-native annotation engine with Form XObject appearance streams (`/AP`), raw preservation, coordinate transforms, and undo/redo support.

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| PDF Highlight Annotation (`/Highlight`) | ✅ | `PdfNativeHighlightAnnotation` / `PdfAnnotationBuilder` | `pdf_native_annotation_entities_test.dart`, `pdf_annotation_parser_builder_test.dart` |
| PDF Underline Annotation (`/Underline`) | ✅ | `PdfNativeUnderlineAnnotation` / `PdfAnnotationBuilder` | `pdf_native_annotation_entities_test.dart`, `pdf_annotation_parser_builder_test.dart` |
| PDF StrikeOut Annotation (`/StrikeOut`) | ✅ | `PdfNativeStrikeOutAnnotation` / `PdfAnnotationBuilder` | `pdf_native_annotation_entities_test.dart`, `pdf_annotation_parser_builder_test.dart` |
| PDF Ink / Freehand Annotation (`/Ink`) | ✅ | `PdfNativeInkAnnotation` / `PdfAnnotationBuilder` | `pdf_native_annotation_entities_test.dart`, `pdf_annotation_parser_builder_test.dart` |
| PDF FreeText Annotation (`/FreeText`) | ✅ | `PdfNativeFreeTextAnnotation` / `PdfAnnotationBuilder` | `pdf_native_annotation_entities_test.dart`, `pdf_annotation_parser_builder_test.dart` |
| PDF Sticky Note / Text (`/Text`) | ✅ | `PdfNativeStickyNoteAnnotation` / `PdfAnnotationBuilder` | `pdf_native_annotation_entities_test.dart`, `pdf_annotation_parser_builder_test.dart` |
| Unknown / Raw Annotation Preservation | ✅ | `PdfNativeRawAnnotation` / `PdfAnnotationParser` | `pdf_native_annotation_entities_test.dart`, `pdf_native_interoperability_test.dart` |
| Native Annotation Engine CRUD | ✅ | `DefaultPdfNativeAnnotationEngine` | `pdf_native_annotation_engine_test.dart` |
| Synchronous Persistence & Undo/Redo | ✅ | `PdfNativeAnnotationService` / `ReaderUndoStack` | `phase6b_native_annotation_service_test.dart` |
| Page Flattening Engine | ✅ | `DefaultPdfNativeAnnotationEngine.flattenAnnotations` | `pdf_native_annotation_engine_test.dart` |
| JSON / FDF Export & Import | ✅ | `PdfNativeAnnotationService` | `phase6b_native_annotation_service_test.dart` |
| Cross-Viewer Interoperability & Preserving 6A | ✅ | `DefaultPdfNativeAnnotationEngine` | `pdf_native_interoperability_test.dart` |

## Quality gates (current)

- `flutter test` (titan_reader): 433 tests passing (100% pass rate)
- `dart analyze project_titan/apps/titan_reader`: 0 issues
- Regression: titan_pdf (5), titan_quiz (31), titan_quiz_ai (42) and
  QuizForge AI (234) suites all passing (745 / 745 total workspace tests)

