import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('KnowledgeChunkBuilder Tests', () {
    late KnowledgeChunkBuilder chunkBuilder;

    setUp(() {
      chunkBuilder = const KnowledgeChunkBuilder();
    });

    test('returns empty list for empty input', () {
      final chunks = chunkBuilder.buildChunks('');
      expect(chunks, isEmpty);
    });

    test('returns single chunk if text length is less than maxChunkSize', () {
      const text = 'Short paragraph for testing.';
      final chunks = chunkBuilder.buildChunks(text);

      expect(chunks.length, equals(1));
      expect(chunks.first, equals(text));
    });

    test('chunks text deterministically respecting paragraph boundaries', () {
      final p1 = 'A' * 600;
      final p2 = 'B' * 600;
      final text = '$p1\n\n$p2';

      const options = KnowledgeChunkOptions(maxChunkSize: 700, overlap: 0);
      final chunks = chunkBuilder.buildChunks(text, options: options);

      expect(chunks.length, equals(2));
      expect(chunks[0], equals(p1));
      expect(chunks[1], equals(p2));
    });

    test('handles overlap between chunks correctly', () {
      final p1 = 'First paragraph content that is long enough.';
      final p2 = 'Second paragraph content that follows after.';
      final text = '$p1\n\n$p2';

      const options = KnowledgeChunkOptions(maxChunkSize: 50, overlap: 15);
      final chunks = chunkBuilder.buildChunks(text, options: options);

      expect(chunks.length, greaterThan(1));
      expect(chunks[1], contains('long enough.'));
    });
  });
}
