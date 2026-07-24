import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('KnowledgeObjectFactory Tests', () {
    late KnowledgeObjectFactory factory;

    setUp(() {
      factory = KnowledgeObjectFactory();
    });

    test('creates immutable KnowledgeObject from text chunk', () {
      const chunkText =
          'The Fundamental Rights in the Indian Constitution are enshrined in Part III.';
      final obj = factory.createFromChunk(
        chunkText: chunkText,
        chunkIndex: 0,
        totalChunks: 1,
        sourceTitle: 'Indian Polity Notes',
        type: KnowledgeType.note,
        source: 'local://polity.txt',
        subjects: ['Polity'],
        topics: ['Fundamental Rights'],
      );

      expect(obj.title, equals('Indian Polity Notes'));
      expect(obj.type, equals(KnowledgeType.note));
      expect(obj.source, equals('local://polity.txt'));
      expect(obj.subjects, equals(['Polity']));
      expect(obj.topics, equals(['Fundamental Rights']));
      expect(obj.metadata['chunkIndex'], equals(0));
      expect(obj.metadata['totalChunks'], equals(1));
      expect(obj.metadata['wordCount'], equals(12));
      expect(obj.metadata['fullChunkText'], equals(chunkText));
      expect(obj.summary, equals(chunkText));
    });

    test('appends part number to title when totalChunks > 1', () {
      final obj = factory.createFromChunk(
        chunkText: 'Chunk content snippet',
        chunkIndex: 1,
        totalChunks: 3,
        sourceTitle: 'Economic Survey',
        type: KnowledgeType.report,
        baseId: 'cko_eco_100',
      );

      expect(obj.id, equals('cko_eco_100-chunk-2'));
      expect(obj.title, equals('Economic Survey (Part 2/3)'));
    });
  });
}
