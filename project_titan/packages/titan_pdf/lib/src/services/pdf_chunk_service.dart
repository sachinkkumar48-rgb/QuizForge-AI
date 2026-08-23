import '../models/chunk_options.dart';
import '../models/learning_document_chunk.dart';
import '../models/learning_page.dart';
import '../models/pdf_chunk.dart';
import '../models/text_provenance.dart';
import 'token_estimator.dart';

/// Domain service responsible for segmenting document text into structured
/// [PdfChunk] and [LearningDocumentChunk] objects.
class PdfChunkService {
  final TokenEstimator _tokenEstimator;

  const PdfChunkService({
    TokenEstimator tokenEstimator = const TokenEstimator(),
  }) : _tokenEstimator = tokenEstimator;

  /// Chunks [text] into a list of legacy [PdfChunk] objects based on [options].
  List<PdfChunk> chunkText({
    required String documentId,
    required String text,
    ChunkOptions options = const ChunkOptions(),
    int startPage = 1,
    int endPage = 1,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];

    final rawParagraphs = options.preserveParagraphs
        ? trimmed.split(RegExp(r'\n\s*\n'))
        : [trimmed];

    final chunks = <PdfChunk>[];
    var currentChunkText = StringBuffer();
    var chunkIndex = 0;

    for (final paragraph in rawParagraphs) {
      final pText = paragraph.trim();
      if (pText.isEmpty) continue;

      if (currentChunkText.length + pText.length + 1 <= options.maxCharacters) {
        if (currentChunkText.isNotEmpty) {
          currentChunkText.write('\n\n');
        }
        currentChunkText.write(pText);
      } else {
        if (currentChunkText.length >= options.minChunkSize) {
          final chunkStr = currentChunkText.toString();
          chunks.add(
            PdfChunk(
              chunkId: '${documentId}_chunk_$chunkIndex',
              documentId: documentId,
              index: chunkIndex,
              text: chunkStr,
              startPage: startPage,
              endPage: endPage,
              tokenEstimate: _tokenEstimator.estimateTokens(chunkStr),
            ),
          );
          chunkIndex++;
        }

        // Apply overlap if configured
        currentChunkText = StringBuffer();
        if (options.overlapCharacters > 0 && chunks.isNotEmpty) {
          final lastText = chunks.last.text;
          final overlapLen = options.overlapCharacters < lastText.length
              ? options.overlapCharacters
              : lastText.length;
          final overlapStr = lastText.substring(lastText.length - overlapLen);
          currentChunkText.write(overlapStr);
          currentChunkText.write('\n\n');
        }
        currentChunkText.write(pText);
      }
    }

    if (currentChunkText.length >= options.minChunkSize) {
      final chunkStr = currentChunkText.toString();
      chunks.add(
        PdfChunk(
          chunkId: '${documentId}_chunk_$chunkIndex',
          documentId: documentId,
          index: chunkIndex,
          text: chunkStr,
          startPage: startPage,
          endPage: endPage,
          tokenEstimate: _tokenEstimator.estimateTokens(chunkStr),
        ),
      );
    }

    return chunks;
  }

  /// Chunks a collection of [LearningPage]s into deterministic [LearningDocumentChunk]s,
  /// preserving page range boundaries, reading order, provenance, script classification, and confidence.
  List<LearningDocumentChunk> chunkLearningPages({
    required String documentId,
    required List<LearningPage> pages,
    ChunkOptions options = const ChunkOptions(),
  }) {
    if (pages.isEmpty) return const [];

    final chunks = <LearningDocumentChunk>[];
    var currentChunkText = StringBuffer();
    var currentStartPage = pages.first.pageNumber;
    var currentEndPage = pages.first.pageNumber;
    var currentProvenances = <TextProvenance>{};
    var currentScripts = <String>{};
    var confidenceSum = 0.0;
    var pageCountInChunk = 0;
    var chunkIndex = 0;

    void flushCurrentChunk() {
      if (currentChunkText.length >= options.minChunkSize) {
        final chunkStr = currentChunkText.toString();
        final finalProvenance = currentProvenances.length > 1
            ? TextProvenance.mixed
            : (currentProvenances.firstOrNull ?? TextProvenance.nativePdf);

        final finalScript = currentScripts.contains('bilingual') ||
                (currentScripts.contains('devanagari') &&
                    currentScripts.contains('latin'))
            ? 'bilingual'
            : (currentScripts.firstOrNull ?? 'latin');

        final avgConfidence = pageCountInChunk > 0
            ? (confidenceSum / pageCountInChunk).clamp(0.0, 1.0)
            : 1.0;

        chunks.add(
          LearningDocumentChunk(
            chunkId: '${documentId}_chunk_$chunkIndex',
            documentId: documentId,
            index: chunkIndex,
            text: chunkStr,
            startPage: currentStartPage,
            endPage: currentEndPage,
            provenance: finalProvenance,
            tokenEstimate: _tokenEstimator.estimateTokens(chunkStr),
            characterCount: chunkStr.length,
            script: finalScript,
            confidence: avgConfidence,
          ),
        );
        chunkIndex++;
      }
    }

    for (final page in pages) {
      final pText = page.text.trim();
      if (pText.isEmpty) continue;

      final paragraphs = options.preserveParagraphs
          ? pText.split(RegExp(r'\n\s*\n'))
          : [pText];

      for (final paragraph in paragraphs) {
        final paraTrimmed = paragraph.trim();
        if (paraTrimmed.isEmpty) continue;

        if (currentChunkText.length + paraTrimmed.length + 1 <=
            options.maxCharacters) {
          if (currentChunkText.isNotEmpty) {
            currentChunkText.write('\n\n');
          } else {
            currentStartPage = page.pageNumber;
            currentProvenances.clear();
            currentScripts.clear();
            confidenceSum = 0.0;
            pageCountInChunk = 0;
          }
          currentChunkText.write(paraTrimmed);
          currentEndPage = page.pageNumber;
          currentProvenances.add(page.provenance);
          currentScripts.add(page.script);
          confidenceSum += page.confidence;
          pageCountInChunk++;
        } else {
          flushCurrentChunk();

          // Prepare next chunk with overlap if requested
          currentChunkText = StringBuffer();
          currentStartPage = page.pageNumber;
          currentEndPage = page.pageNumber;
          currentProvenances.clear();
          currentScripts.clear();
          confidenceSum = page.confidence;
          pageCountInChunk = 1;

          if (options.overlapCharacters > 0 && chunks.isNotEmpty) {
            final lastText = chunks.last.text;
            final overlapLen = options.overlapCharacters < lastText.length
                ? options.overlapCharacters
                : lastText.length;
            final overlapStr = lastText.substring(lastText.length - overlapLen);
            currentChunkText.write(overlapStr);
            currentChunkText.write('\n\n');
          }

          currentChunkText.write(paraTrimmed);
          currentProvenances.add(page.provenance);
          currentScripts.add(page.script);
        }
      }
    }

    flushCurrentChunk();
    return chunks;
  }
}
