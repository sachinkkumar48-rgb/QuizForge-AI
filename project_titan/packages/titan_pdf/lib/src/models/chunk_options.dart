import 'package:meta/meta.dart';

/// Immutable configuration options for PDF document text chunking.
@immutable
class ChunkOptions {
  final int maxCharacters;
  final int overlapCharacters;
  final bool preserveParagraphs;
  final bool preserveHeadings;
  final int minChunkSize;

  const ChunkOptions({
    this.maxCharacters = 1000,
    this.overlapCharacters = 100,
    this.preserveParagraphs = true,
    this.preserveHeadings = true,
    this.minChunkSize = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChunkOptions &&
          runtimeType == other.runtimeType &&
          maxCharacters == other.maxCharacters &&
          overlapCharacters == other.overlapCharacters &&
          preserveParagraphs == other.preserveParagraphs &&
          preserveHeadings == other.preserveHeadings &&
          minChunkSize == other.minChunkSize;

  @override
  int get hashCode =>
      maxCharacters.hashCode ^
      overlapCharacters.hashCode ^
      preserveParagraphs.hashCode ^
      preserveHeadings.hashCode ^
      minChunkSize.hashCode;

  @override
  String toString() =>
      'ChunkOptions(maxChars: $maxCharacters, overlap: $overlapCharacters, minSize: $minChunkSize)';
}
