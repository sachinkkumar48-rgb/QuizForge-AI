import 'package:flutter_test/flutter_test.dart';
import 'package:titan_notes/titan_notes.dart';

void main() {
  group('NotesRepositoryImpl Tests', () {
    late NotesRepository repository;

    setUp(() {
      repository = NotesRepositoryImpl();
    });

    test('getNoteById retrieves default seeded note', () async {
      final note = await repository.getNoteById('sn_01');
      expect(note, isNotNull);
      expect(note!.title, contains('Preamble'));
      expect(note.tags.isNotEmpty, isTrue);
    });

    test('createNote and getNotesByCollection manage storage', () async {
      final now = DateTime.now();
      final newNote = SmartNote(
        id: 'sn_test_create',
        title: 'New Directive Principles Note',
        content: 'DPSP details',
        collectionId: 'col_polity',
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

      await repository.createNote(newNote);
      final notes = await repository.getNotesByCollection('col_polity');
      expect(notes.length, equals(2));
    });

    test('updateNote records new version history', () async {
      final existing = await repository.getNoteById('sn_01');
      expect(existing, isNotNull);

      final updated = existing!.copyWith(content: 'Updated Preamble content.');
      await repository.updateNote(updated);

      final history = await repository.getVersionHistory('sn_01');
      expect(history.length, equals(2));
    });

    test('deleteNote removes note from store', () async {
      final deleted = await repository.deleteNote('sn_01');
      expect(deleted, isTrue);

      final note = await repository.getNoteById('sn_01');
      expect(note, isNull);
    });
  });
}
