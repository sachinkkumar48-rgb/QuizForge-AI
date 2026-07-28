import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('StructuralParser Tests', () {
    late StructuralParser parser;

    setUp(() {
      parser = StructuralParser();
    });

    test('Parses Markdown headers, code blocks, tables, and bullet lists', () {
      const markdown = '''
Course: Indian Polity
Module 1: Constitutional Framework
Chapter 1: Preamble
# Preamble to the Constitution
## Key Principles
- Sovereign
- Socialist
- Secular

| Feature | Adopted From |
| Sovereign | UK |
| Fundamental Rights | USA |

```dart
void main() => print("Law");
```

> "We the people of India..."
''';

      final structure = parser.parse(markdown);

      expect(structure.course, equals('Indian Polity'));
      expect(structure.module, equals('Constitutional Framework'));
      expect(structure.chapter, equals('Preamble'));
      expect(structure.title, equals('Preamble to the Constitution'));

      expect(structure.sections, contains('Key Principles'));
      expect(structure.blocks.length, greaterThanOrEqualTo(5));

      final headingBlocks = structure.blocks.whereType<HeadingBlock>().toList();
      expect(headingBlocks.first.text, equals('Preamble to the Constitution'));

      final listBlocks = structure.blocks.whereType<BulletListBlock>().toList();
      expect(listBlocks.first.items, contains('Sovereign'));

      final tableBlocks = structure.blocks.whereType<TableBlock>().toList();
      expect(tableBlocks.first.headers, contains('Feature'));

      final codeBlocks = structure.blocks.whereType<CodeBlock>().toList();
      expect(codeBlocks.first.language, equals('dart'));

      final quoteBlocks = structure.blocks.whereType<QuoteBlock>().toList();
      expect(quoteBlocks.first.quote, contains('We the people'));
    });
  });
}
