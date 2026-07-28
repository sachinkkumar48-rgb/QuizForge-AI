import 'package:flutter_test/flutter_test.dart';
import 'package:titan_notes/titan_notes.dart';

void main() {
  group('Smart Note & Domain Models Tests', () {
    test('SmartNote instantiates and serializes to JSON round-trip', () {
      final now = DateTime.now();
      final note = SmartNote(
        id: 'n_test_1',
        title: 'Fundamental Rights Overview',
        content: 'Article 14 to 32 covers fundamental rights in India.',
        type: NoteType.manual,
        knowledgeNodeIds: const ['node_fr'],
        sections: const [
          NoteSection(
              id: 'sec_1',
              heading: 'Article 14',
              content: 'Equality before law.',
              orderIndex: 0),
        ],
        tags: const [
          NoteTag(id: 't1', label: 'POLITY'),
        ],
        attachments: const [
          NoteAttachment(
              id: 'a1',
              fileName: 'diagram.png',
              filePath: '/path/d.png',
              mimeType: 'image/png',
              fileSizeBytes: 1024),
        ],
        bookmarks: [
          NoteBookmark(
              id: 'bm1',
              noteId: 'n_test_1',
              label: 'Art 14',
              offsetIndex: 10,
              createdAt: now),
        ],
        versions: [
          NoteVersion(
              versionNumber: 1,
              title: 'FR Overview',
              content: 'Draft content',
              author: 'Aspirant',
              createdAt: now),
        ],
        comments: const [],
        references: const [],
        highlights: const [],
        annotations: const [],
        summary: NoteSummary(
          overview: 'Overview of Fundamental Rights.',
          keyTakeaways: const ['Equality before law'],
          upscRelevance: const ['GS II'],
        ),
        createdAt: now,
        updatedAt: now,
      );

      expect(note.id, equals('n_test_1'));
      expect(note.title, equals('Fundamental Rights Overview'));
      expect(note.tags.first.label, equals('POLITY'));

      final json = note.toJson();
      final restored = SmartNote.fromJson(json);
      expect(restored.id, equals(note.id));
      expect(restored.title, equals(note.title));
      expect(restored.sections.first.heading, equals('Article 14'));
    });

    test('NoteTypeX and HighlightColorX extensions work as expected', () {
      expect(NoteType.manual.label, equals('Manual Note'));
      expect(NoteType.aiGenerated.label, equals('AI Generated'));
      expect(HighlightColor.yellow.hexCode, equals('#FFF176'));
    });
  });
}
