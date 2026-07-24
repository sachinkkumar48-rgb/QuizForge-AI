import 'package:meta/meta.dart';

/// Configuration options for [KnowledgeChunkBuilder].
@immutable
class KnowledgeChunkOptions {
  /// Maximum character count per chunk (default: 1000).
  final int maxChunkSize;

  /// Character overlap between adjacent chunks (default: 100).
  final int overlap;

  /// Minimum character length required for a standalone chunk (default: 50).
  final int minChunkSize;

  /// Constructs immutable [KnowledgeChunkOptions].
  const KnowledgeChunkOptions({
    this.maxChunkSize = 1000,
    this.overlap = 100,
    this.minChunkSize = 50,
  })  : assert(maxChunkSize > 0, 'maxChunkSize must be positive'),
        assert(overlap >= 0, 'overlap cannot be negative'),
        assert(
            overlap < maxChunkSize, 'overlap must be less than maxChunkSize'),
        assert(minChunkSize > 0, 'minChunkSize must be positive');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeChunkOptions &&
        other.maxChunkSize == maxChunkSize &&
        other.overlap == overlap &&
        other.minChunkSize == minChunkSize;
  }

  @override
  int get hashCode => Object.hash(maxChunkSize, overlap, minChunkSize);
}

/// Splits normalized text into deterministic, semantic content chunks
/// while preserving paragraph and sentence boundaries.
class KnowledgeChunkBuilder {
  /// Default chunking options.
  final KnowledgeChunkOptions defaultOptions;

  /// Constructs a [KnowledgeChunkBuilder] with optional default configuration.
  const KnowledgeChunkBuilder({
    this.defaultOptions = const KnowledgeChunkOptions(),
  });

  /// Splits [text] into a list of string chunks according to [options].
  List<String> buildChunks(
    String text, {
    KnowledgeChunkOptions? options,
  }) {
    final opts = options ?? defaultOptions;
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return const [];
    }

    if (trimmed.length <= opts.maxChunkSize) {
      return [trimmed];
    }

    final chunks = <String>[];
    // Split input into semantic paragraphs first
    final paragraphs =
        trimmed.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    var currentChunkBuffer = StringBuffer();

    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();

      // If a single paragraph exceeds maxChunkSize, break it by sentences or lines
      if (paragraph.length > opts.maxChunkSize) {
        if (currentChunkBuffer.isNotEmpty) {
          chunks.add(currentChunkBuffer.toString().trim());
          currentChunkBuffer.clear();
        }

        final subChunks = _splitLargeParagraph(paragraph, opts);
        chunks.addAll(subChunks);
        continue;
      }

      // Check if adding this paragraph exceeds maxChunkSize
      final potentialLength = currentChunkBuffer.isEmpty
          ? paragraph.length
          : currentChunkBuffer.length + 2 + paragraph.length;

      if (potentialLength <= opts.maxChunkSize) {
        if (currentChunkBuffer.isNotEmpty) {
          currentChunkBuffer.write('\n\n');
        }
        currentChunkBuffer.write(paragraph);
      } else {
        // Finalize current chunk
        chunks.add(currentChunkBuffer.toString().trim());

        // Handle overlap if configured
        currentChunkBuffer.clear();
        if (opts.overlap > 0 && chunks.isNotEmpty) {
          final previousText = chunks.last;
          final overlapStart = previousText.length > opts.overlap
              ? previousText.length - opts.overlap
              : 0;
          final overlapSnippet = previousText.substring(overlapStart).trim();
          if (overlapSnippet.isNotEmpty) {
            currentChunkBuffer.write(overlapSnippet);
            currentChunkBuffer.write('\n\n');
          }
        }
        currentChunkBuffer.write(paragraph);
      }
    }

    if (currentChunkBuffer.isNotEmpty) {
      final remaining = currentChunkBuffer.toString().trim();
      if (remaining.isNotEmpty) {
        // If remaining is smaller than minChunkSize and we already have chunks, append to last chunk
        if (remaining.length < opts.minChunkSize && chunks.isNotEmpty) {
          final last = chunks.removeLast();
          chunks.add('$last\n\n$remaining');
        } else {
          chunks.add(remaining);
        }
      }
    }

    return chunks;
  }

  List<String> _splitLargeParagraph(
      String paragraph, KnowledgeChunkOptions opts) {
    final subChunks = <String>[];
    final sentences = paragraph.split(RegExp(r'(?<=[.!?])\s+'));

    var buffer = StringBuffer();

    for (final sentence in sentences) {
      if (sentence.length > opts.maxChunkSize) {
        // Fallback: hard chop on space boundaries for huge unbroken sentences
        if (buffer.isNotEmpty) {
          subChunks.add(buffer.toString().trim());
          buffer.clear();
        }
        subChunks.addAll(_hardChopText(sentence, opts));
        continue;
      }

      final potentialLength = buffer.isEmpty
          ? sentence.length
          : buffer.length + 1 + sentence.length;
      if (potentialLength <= opts.maxChunkSize) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(sentence);
      } else {
        subChunks.add(buffer.toString().trim());
        buffer.clear();
        buffer.write(sentence);
      }
    }

    if (buffer.isNotEmpty) {
      subChunks.add(buffer.toString().trim());
    }

    return subChunks;
  }

  List<String> _hardChopText(String text, KnowledgeChunkOptions opts) {
    final results = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = start + opts.maxChunkSize;
      if (end >= text.length) {
        results.add(text.substring(start).trim());
        break;
      }
      // Try to chop on space
      final spaceIndex = text.lastIndexOf(' ', end);
      if (spaceIndex > start) {
        end = spaceIndex;
      }
      results.add(text.substring(start, end).trim());
      start = end + 1;
    }
    return results;
  }
}
