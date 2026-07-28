import 'package:flutter_test/flutter_test.dart';
import 'package:titan_notes/titan_notes.dart';

void main() {
  group('Smart Notes Engine Use Cases Tests', () {
    late NotesRepository repository;
    late CreateNoteUseCase createNoteUseCase;
    late UpdateNoteUseCase updateNoteUseCase;
    late DeleteNoteUseCase deleteNoteUseCase;
    late GetNotesByContentUseCase getNotesByContentUseCase;
    late AddNoteBookmarkUseCase addNoteBookmarkUseCase;
    late GenerateNoteSummaryUseCase generateNoteSummaryUseCase;
    late GetNoteVersionHistoryUseCase getNoteVersionHistoryUseCase;
    late OrganizeNotesUseCase organizeNotesUseCase;
    late EnhanceNoteWithAiUseCase enhanceNoteWithAiUseCase;
    late ConvertNoteToFlashcardsUseCase convertNoteToFlashcardsUseCase;
    late LinkNoteToKnowledgeNodeUseCase linkNoteToKnowledgeNodeUseCase;

    setUp(() {
      repository = NotesRepositoryImpl();
      createNoteUseCase = CreateNoteUseCase(repository);
      updateNoteUseCase = UpdateNoteUseCase(repository);
      deleteNoteUseCase = DeleteNoteUseCase(repository);
      getNotesByContentUseCase = GetNotesByContentUseCase(repository);
      addNoteBookmarkUseCase = AddNoteBookmarkUseCase(repository);
      generateNoteSummaryUseCase = const GenerateNoteSummaryUseCase();
      getNoteVersionHistoryUseCase = GetNoteVersionHistoryUseCase(repository);
      organizeNotesUseCase = const OrganizeNotesUseCase();
      enhanceNoteWithAiUseCase = EnhanceNoteWithAiUseCase(repository);
      convertNoteToFlashcardsUseCase = const ConvertNoteToFlashcardsUseCase();
      linkNoteToKnowledgeNodeUseCase =
          LinkNoteToKnowledgeNodeUseCase(repository);
    });

    test('Create, Update, Delete use cases execute successfully', () async {
      final now = DateTime.now();
      final note = SmartNote(
        id: 'uc_note_01',
        title: 'Fundamental Duties',
        content: 'Article 51A details 11 fundamental duties.',
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

      final created = await createNoteUseCase.execute(note);
      expect(created.title, equals('Fundamental Duties'));

      final updated = await updateNoteUseCase
          .execute(created.copyWith(title: 'Updated Duties'));
      expect(updated.title, equals('Updated Duties'));

      final deleted = await deleteNoteUseCase.execute('uc_note_01');
      expect(deleted, isTrue);
    });

    test(
        'GetNotesByContentUseCase, AddNoteBookmarkUseCase, GetNoteVersionHistoryUseCase, OrganizeNotesUseCase execute correctly',
        () async {
      final notes = await getNotesByContentUseCase.execute('lc_video_01');
      expect(notes.isNotEmpty, isTrue);

      final bm = await addNoteBookmarkUseCase.execute(
        NoteBookmark(
          id: 'bm_test_1',
          noteId: 'sn_01',
          label: 'Test Bookmark',
          offsetIndex: 0,
          createdAt: DateTime.now(),
        ),
      );
      expect(bm.label, equals('Test Bookmark'));

      final history = await getNoteVersionHistoryUseCase.execute('sn_01');
      expect(history.isNotEmpty, isTrue);

      final organized = organizeNotesUseCase.execute(notes);
      expect(organized.isNotEmpty, isTrue);
    });

    test(
        'EnhanceNoteWithAiUseCase and ConvertNoteToFlashcardsUseCase execute correctly',
        () async {
      final note = await repository.getNoteById('sn_01');
      expect(note, isNotNull);

      final enhanced = await enhanceNoteWithAiUseCase.execute(note!);
      expect(enhanced.type, equals(NoteType.aiGenerated));

      final flashcards = convertNoteToFlashcardsUseCase.execute(note);
      expect(flashcards.isNotEmpty, isTrue);

      final summary = generateNoteSummaryUseCase.execute(note);
      expect(summary.overview, isNotEmpty);
    });

    test('LinkNoteToKnowledgeNodeUseCase updates knowledge node list',
        () async {
      final note = await repository.getNoteById('sn_01');
      expect(note, isNotNull);

      final updated = await linkNoteToKnowledgeNodeUseCase.execute(
          note!, 'node_kesavananda');
      expect(updated.knowledgeNodeIds, contains('node_kesavananda'));
    });

    test('NotesEngineIntegrator AI, Video, PDF, and Revision integrations work',
        () async {
      const integrator = NotesEngineIntegrator();
      final note = (await repository.getNoteById('sn_01'))!;

      final explanation =
          await integrator.explainNote(userId: 'u1', note: note);
      expect(explanation, isNotNull);
      expect(explanation!.content, contains('AI Explanation'));

      final expanded = await integrator.expandNote(userId: 'u1', note: note);
      expect(expanded!.content, contains('Expanded Context'));

      final timestampNote = integrator.createTimestampNote(
        id: 'ts_01',
        videoId: 'vid_100',
        title: 'Video Bookmark',
        content: 'Key explanation at 120s',
        timestampSeconds: 120,
      );
      expect(timestampNote.type, equals(NoteType.timestamp));
      expect(timestampNote.timestampSeconds, equals(120));

      final pdfNote = integrator.createPdfPageNote(
        id: 'pdf_01',
        pdfId: 'doc_200',
        pageNumber: 15,
        title: 'PDF Marginalia',
        content: 'Analysis of Page 15',
      );
      expect(pdfNote.type, equals(NoteType.pdf));
      expect(pdfNote.pageNumber, equals(15));

      final revisionItem = integrator.createRevisionItemForNote(note);
      expect(revisionItem.topic, equals(note.title));
      expect(revisionItem.intervalDays, equals(1));
    });
  });
}
