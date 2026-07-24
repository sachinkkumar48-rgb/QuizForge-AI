import '../models/chunk_options.dart';
import '../models/pdf_chunk.dart';
import 'token_estimator.dart';

/// Domain service responsible for segmenting document text into structured [PdfChunk] objects.
class PdfChunkService {
  final TokenEstimator _tokenEstimator;

  const PdfChunkService({
    TokenEstimator tokenEstimator = const TokenEstimator(),
  }) : _tokenEstimator = tokenEstimator;

  /// Chunks [text] into a list of [PdfChunk] objects based on [options].
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
}
