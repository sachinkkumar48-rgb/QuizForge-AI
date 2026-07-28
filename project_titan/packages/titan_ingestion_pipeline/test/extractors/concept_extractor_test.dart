import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('ConceptExtractionEngine Tests', () {
    late ConceptExtractionEngine extractor;

    setUp(() {
      extractor = ConceptExtractionEngine();
    });

    test('Extracts Articles, Acts, Dates, and Definitions', () async {
      const text = '''
Article 21 guarantees Right to Life. 
The Right to Information Act, 2005 came into force in 2005.
"Preamble" is defined as the introduction to the Constitution.
''';

      final result = await extractor.extract(text, 'Constitutional Law');

      expect(
          result.concepts
              .any((KnowledgeConcept c) => c.name.contains('Article 21')),
          isTrue);
      expect(
          result.concepts
              .any((KnowledgeConcept c) => c.type == ConceptType.act),
          isTrue);
      expect(
          result.concepts
              .any((KnowledgeConcept c) => c.type == ConceptType.date),
          isTrue);
      expect(result.glossary.any((GlossaryItem g) => g.term == 'Preamble'),
          isTrue);
      expect(result.keywords, contains('Article 21'));
    });
  });
}
