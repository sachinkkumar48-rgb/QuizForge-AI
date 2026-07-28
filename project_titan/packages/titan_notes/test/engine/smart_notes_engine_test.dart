import 'package:flutter_test/flutter_test.dart';
import 'package:titan_notes/titan_notes.dart';

void main() {
  group('SmartNotesEngine Pure Dart Tests', () {
    late SmartNotesEngine engine;

    setUp(() {
      engine = const SmartNotesEngine();
    });

    test('mergeNotes merges multiple notes into unified document', () {
      final now = DateTime.now();
      final n1 = SmartNote(
        id: 'n1',
        title: 'Note 1',
        content: 'Content 1',
        knowledgeNodeIds: const ['k1'],
        sections: const [],
        tags: const [NoteTag(id: 't1', label: 'POLITY')],
        attachments: const [],
        bookmarks: const [],
        versions: const [],
        comments: const [],
        references: const [],
        highlights: const [],
        annotations: const [],
        createdAt: now,
        updatedAt: now,
      );

      final n2 = SmartNote(
        id: 'n2',
        title: 'Note 2',
        content: 'Content 2',
        knowledgeNodeIds: const ['k2'],
        sections: const [],
        tags: const [NoteTag(id: 't2', label: 'PREAMBLE')],
        attachments: const [],
        bookmarks: const [],
        versions: const [],
        comments: const [],
        references: const [],
        highlights: const [],
        annotations: const [],
        createdAt: now,
        updatedAt: now,
      );

      final merged =
          engine.mergeNotes([n1, n2], newTitle: 'Merged Polity Notes');
      expect(merged.title, equals('Merged Polity Notes'));
      expect(merged.content, contains('Content 1'));
      expect(merged.content, contains('Content 2'));
      expect(merged.tags.length, equals(2));
      expect(merged.knowledgeNodeIds.length, equals(2));
    });

    test('organizeNotes groups notes by tag or collection', () {
      final now = DateTime.now();
      final n1 = SmartNote(
        id: 'n1',
        title: 'Title 1',
        content: 'Content 1',
        collectionId: 'col_a',
        knowledgeNodeIds: const [],
        sections: const [],
        tags: const [],
        attachments: const [],
        bookmarks: const [],
        versions: const [],
        comments: const [],
        references: const [],
        highlights: const [],
        annotations: const [],
        createdAt: now,
        updatedAt: now,
      );

      final organized = engine.organizeNotes([n1]);
      expect(organized.containsKey('col_a'), isTrue);
      expect(organized['col_a']!.length, equals(1));
    });

    test('deduplicate removes identical duplicate notes', () {
      final now = DateTime.now();
      final n1 = SmartNote(
        id: 'n1',
        title: 'Duplicate Title',
        content: 'Same content',
        knowledgeNodeIds: const [],
        sections: const [],
        tags: const [],
        attachments: const [],
        bookmarks: const [],
        versions: const [],
        comments: const [],
        references: const [],
        highlights: const [],
        annotations: const [],
        createdAt: now,
        updatedAt: now,
      );

      final n2 = SmartNote(
        id: 'n2',
        title: 'Duplicate Title',
        content: 'Same content',
        knowledgeNodeIds: const [],
        sections: const [],
        tags: const [],
        attachments: const [],
        bookmarks: const [],
        versions: const [],
        comments: const [],
        references: const [],
        highlights: const [],
        annotations: const [],
        createdAt: now,
        updatedAt: now,
      );

      final clean = engine.deduplicate([n1, n2]);
      expect(clean.length, equals(1));
    });

    test('aiEnhancement and summarize generate structured summaries', () {
      final now = DateTime.now();
      final note = SmartNote(
        id: 'n1',
        title: 'Preamble Details',
        content: 'Preamble is integral to Indian Constitution.',
        knowledgeNodeIds: const [],
        sections: const [],
        tags: const [],
        attachments: const [],
        bookmarks: const [],
        versions: const [],
        comments: const [],
        references: const [],
        highlights: const [],
        annotations: const [],
        createdAt: now,
        updatedAt: now,
      );

      final enhanced = engine.aiEnhancement(note);
      expect(enhanced.type, equals(NoteType.aiGenerated));
      expect(enhanced.summary, isNotNull);
      expect(enhanced.summary!.overview, contains('Preamble'));
    });
  });
}
