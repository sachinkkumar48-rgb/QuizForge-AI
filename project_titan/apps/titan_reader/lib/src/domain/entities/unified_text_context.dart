import 'package:meta/meta.dart';

import '../../pdf/pdf_engine_contracts.dart';
import '../word_normalizer.dart';
import 'ai_reading_models.dart';
import 'ai_reading_task.dart';
import 'normalized_page_rect.dart';
import 'ocr/ocr_search_selection.dart';

import 'package:titan_pdf/titan_pdf.dart' show TextProvenance;

export 'package:titan_pdf/titan_pdf.dart' show TextProvenance;

/// An engine-independent, unified representation of selected text within
/// TITAN Reader, providing a stable contract for language services
/// (Dictionary, Grammar, Vocabulary) regardless of whether the text originated
/// from native PDF glyphs or an OCR recognition layer.
@immutable
class UnifiedTextContext {
  /// Unique identifier of the document containing this selection.
  final String documentId;

  /// Human-readable title or filename of the document, if available.
  final String? documentName;

  /// 1-based page number where the selection occurred.
  final int pageNumber;

  /// Raw selected text content.
  final String selectedText;

  /// Originating source of this selection (native PDF or OCR).
  final TextProvenance source;

  /// Normalized bounding boxes (0.0 .. 1.0) covering the selected text fragments.
  final List<NormalizedPageRect> selectionBounds;

  /// Optional ISO 639-1 language code (e.g. 'en'), if known.
  final String? languageCode;

  /// Recognition confidence score (1.0 for native digital text, 0.0 .. 1.0 for OCR).
  final double? confidence;

  /// Creation timestamp used for stale-context validation across asynchronous requests.
  final DateTime timestamp;

  const UnifiedTextContext({
    required this.documentId,
    this.documentName,
    required this.pageNumber,
    required this.selectedText,
    required this.source,
    required this.selectionBounds,
    this.languageCode,
    this.confidence,
    required this.timestamp,
  });

  /// Adapts a native [PdfTextSelectionSnapshot] into a [UnifiedTextContext].
  factory UnifiedTextContext.fromNativeSnapshot({
    required String documentId,
    required PdfTextSelectionSnapshot snapshot,
    String? documentName,
    String? languageCode,
    DateTime? timestamp,
  }) {
    final primaryPage = snapshot.primaryPageNumber ?? 1;
    final bounds = snapshot.fragments
        .where((f) => f.pageNumber == primaryPage)
        .map((f) => f.rect)
        .toList();

    return UnifiedTextContext(
      documentId: documentId,
      documentName: documentName,
      pageNumber: primaryPage,
      selectedText: snapshot.text,
      source: TextProvenance.nativePdf,
      selectionBounds: List.unmodifiable(bounds),
      languageCode: languageCode,
      confidence: 1.0,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Adapts an [OcrTextSelection] into a [UnifiedTextContext].
  factory UnifiedTextContext.fromOcrSelection({
    required OcrTextSelection selection,
    String? documentName,
    String? languageCode,
    double? confidence,
    DateTime? timestamp,
  }) {
    return UnifiedTextContext(
      documentId: selection.documentId,
      documentName: documentName,
      pageNumber: selection.pageNumber,
      selectedText: selection.selectedText,
      source: TextProvenance.ocr,
      selectionBounds: List.unmodifiable(selection.boundingBoxes),
      languageCode: languageCode,
      confidence: confidence,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Whether the selection represents a single dictionary-lookable word.
  bool get isSingleWord => WordNormalizer.singleWordFrom(selectedText) != null;

  /// Normalized single word string for dictionary or vocabulary lookup, if single word.
  String? get normalizedWord => WordNormalizer.normalizeWord(selectedText);

  /// Number of characters in the selected text.
  int get characterCount => selectedText.length;

  /// Number of words in the selected text.
  int get wordCount {
    final trimmed = selectedText.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Whether this selection originated from native digital PDF text.
  bool get isNative => source == TextProvenance.nativePdf;

  /// Whether this selection originated from on-device OCR recognition.
  bool get isOcr => source == TextProvenance.ocr;

  /// Converts this context to a standard [PdfTextSelectionSnapshot].
  PdfTextSelectionSnapshot toSnapshot() {
    return PdfTextSelectionSnapshot(
      text: selectedText,
      fragments: selectionBounds
          .map((rect) =>
              PdfSelectionFragment(pageNumber: pageNumber, rect: rect))
          .toList(),
    );
  }

  /// Converts this unified context into a standard [AIReadingRequest] for the AI Assistant.
  AIReadingRequest toAIReadingRequest({
    required AIReadingTask task,
    AIContextScope contextScope = AIContextScope.selection,
    String? userQuestion,
    AISummaryLength summaryLength = AISummaryLength.medium,
    AISimplifyLevel simplifyLevel = AISimplifyLevel.simple,
    String? targetLanguage,
    String? customInstruction,
  }) {
    return AIReadingRequest(
      task: task,
      text: selectedText,
      contextScope: contextScope,
      documentId: documentId,
      documentName: documentName,
      pageNumber: pageNumber,
      userQuestion: userQuestion,
      summaryLength: summaryLength,
      simplifyLevel: simplifyLevel,
      targetLanguage: targetLanguage,
      customInstruction: customInstruction,
    );
  }

  /// Validates whether this context matches [other] in document, page, and text.
  bool isSameContext(UnifiedTextContext? other) {
    if (other == null) return false;
    return documentId == other.documentId &&
        pageNumber == other.pageNumber &&
        selectedText == other.selectedText;
  }

  /// Creates a copy with optionally updated fields.
  UnifiedTextContext copyWith({
    String? documentId,
    String? documentName,
    int? pageNumber,
    String? selectedText,
    TextProvenance? source,
    List<NormalizedPageRect>? selectionBounds,
    String? languageCode,
    double? confidence,
    DateTime? timestamp,
  }) {
    return UnifiedTextContext(
      documentId: documentId ?? this.documentId,
      documentName: documentName ?? this.documentName,
      pageNumber: pageNumber ?? this.pageNumber,
      selectedText: selectedText ?? this.selectedText,
      source: source ?? this.source,
      selectionBounds: selectionBounds ?? this.selectionBounds,
      languageCode: languageCode ?? this.languageCode,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedTextContext &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          documentName == other.documentName &&
          pageNumber == other.pageNumber &&
          selectedText == other.selectedText &&
          source == other.source &&
          languageCode == other.languageCode &&
          confidence == other.confidence &&
          _listEquals(selectionBounds, other.selectionBounds);

  @override
  int get hashCode => Object.hash(
        documentId,
        documentName,
        pageNumber,
        selectedText,
        source,
        languageCode,
        confidence,
        Object.hashAll(selectionBounds),
      );

  @override
  String toString() =>
      'UnifiedTextContext($source, doc: $documentId, p$pageNumber, "$selectedText", bounds: ${selectionBounds.length})';

  Map<String, Object?> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'pageNumber': pageNumber,
        'selectedText': selectedText,
        'source': source.name,
        'selectionBounds': selectionBounds.map((b) => b.toJson()).toList(),
        'languageCode': languageCode,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UnifiedTextContext.fromJson(Map<String, Object?> json) {
    final rawBounds = json['selectionBounds'] as List<dynamic>? ?? [];
    return UnifiedTextContext(
      documentId: json['documentId'] as String? ?? '',
      documentName: json['documentName'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      selectedText: json['selectedText'] as String? ?? '',
      source: json['source'] == 'ocr'
          ? TextProvenance.ocr
          : TextProvenance.nativePdf,
      selectionBounds: rawBounds
          .map((b) => NormalizedPageRect.fromJson(b as Map<String, Object?>))
          .toList(),
      languageCode: json['languageCode'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
