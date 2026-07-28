import '../models/notes_models.dart';
import 'notes_repository.dart';

/// Concrete offline-first implementation of [NotesRepository].
class NotesRepositoryImpl implements NotesRepository {
  final Map<String, SmartNote> _noteStore = {};
  final Map<String, List<NoteVersion>> _versionStore = {};

  NotesRepositoryImpl({List<SmartNote>? initialNotes}) {
    if (initialNotes != null && initialNotes.isNotEmpty) {
      for (final n in initialNotes) {
        _noteStore[n.id] = n;
        _versionStore[n.id] = List.from(n.versions);
      }
    } else {
      _seedDefaultNotes();
    }
  }

  void _seedDefaultNotes() {
    final now = DateTime.now();
    final defaultNote = SmartNote(
      id: 'sn_01',
      title: 'Preamble & Legal Philosophy Notes',
      content:
          'The Preamble is an integral part of the Indian Constitution as established in Kesavananda Bharati vs State of Kerala (1973). It outlines the objective: Justice, Liberty, Equality, Fraternity.',
      type: NoteType.manual,
      contentId: 'lc_video_01',
      collectionId: 'col_polity',
      timestampSeconds: 120,
      knowledgeNodeIds: const ['node_polity_preamble'],
      sections: const [
        NoteSection(
          id: 'sec_1',
          heading: 'Basic Structure Doctrine',
          content:
              'Supreme Court 13-judge bench ruling established non-amendability of core framework.',
          orderIndex: 0,
        ),
      ],
      tags: const [
        NoteTag(id: 't1', label: 'POLITY'),
        NoteTag(id: 't2', label: 'PREAMBLE'),
      ],
      attachments: const [],
      bookmarks: [
        NoteBookmark(
          id: 'bm_01',
          noteId: 'sn_01',
          label: 'Kesavananda ruling excerpt',
          offsetIndex: 50,
          createdAt: now,
        ),
      ],
      versions: [
        NoteVersion(
          versionNumber: 1,
          title: 'Preamble Notes Initial Draft',
          content: 'Initial thoughts on Preamble legal status.',
          author: 'UPSC Aspirant',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      comments: const [],
      references: const [
        NoteReference(
          id: 'ref_1',
          targetType: 'video',
          targetId: 'lc_video_01',
          displayTitle: 'Preamble Video @ 120s',
          timestampSeconds: 120,
        ),
      ],
      highlights: [
        Highlight(
          id: 'h_1',
          contentId: 'lc_video_01',
          highlightedText: 'Kesavananda Bharati vs State of Kerala',
          color: HighlightColor.yellow,
          timestampSeconds: 120,
          note: 'Key case law for Mains answer writing',
          createdAt: now,
        ),
      ],
      annotations: const [],
      summary: NoteSummary(
        overview:
            'Comprehensive breakdown of Constitutional Preamble and Supreme Court rulings.',
        keyTakeaways: const [
          'Preamble is integral to Constitution',
          'Subject to Basic Structure Doctrine'
        ],
        upscRelevance: const ['Direct relevance to GS Paper II Polity'],
      ),
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    );

    _noteStore[defaultNote.id] = defaultNote;
    _versionStore[defaultNote.id] = List.from(defaultNote.versions);
  }

  @override
  Future<SmartNote?> getNoteById(String noteId) async {
    return _noteStore[noteId];
  }

  @override
  Future<List<SmartNote>> getNotesByCollection(String collectionId) async {
    return _noteStore.values
        .where((n) => n.collectionId == collectionId)
        .toList();
  }

  @override
  Future<List<SmartNote>> getNotesByContent(String contentId) async {
    return _noteStore.values.where((n) => n.contentId == contentId).toList();
  }

  @override
  Future<List<SmartNote>> getAllNotes() async {
    return _noteStore.values.toList();
  }

  @override
  Future<SmartNote> createNote(SmartNote note) async {
    _noteStore[note.id] = note;
    _versionStore[note.id] = List.from(note.versions);
    return note;
  }

  @override
  Future<SmartNote> updateNote(SmartNote note) async {
    final currentVersions =
        List<NoteVersion>.from(_versionStore[note.id] ?? []);

    final newVersionNum = currentVersions.length + 1;
    final newVersion = NoteVersion(
      versionNumber: newVersionNum,
      title: note.title,
      content: note.content,
      author: 'Aspirant',
      createdAt: DateTime.now(),
    );

    currentVersions.add(newVersion);
    _versionStore[note.id] = currentVersions;

    final updated = note.copyWith(
      versions: currentVersions,
      updatedAt: DateTime.now(),
    );

    _noteStore[note.id] = updated;
    return updated;
  }

  @override
  Future<bool> deleteNote(String noteId) async {
    final removed = _noteStore.remove(noteId);
    _versionStore.remove(noteId);
    return removed != null;
  }

  @override
  Future<List<NoteVersion>> getVersionHistory(String noteId) async {
    return _versionStore[noteId] ?? const [];
  }

  @override
  Future<NoteBookmark> addBookmark(NoteBookmark bookmark) async {
    final note = _noteStore[bookmark.noteId];
    if (note != null) {
      final updatedBookmarks = List<NoteBookmark>.from(note.bookmarks)
        ..add(bookmark);
      _noteStore[note.id] = note.copyWith(bookmarks: updatedBookmarks);
    }
    return bookmark;
  }

  @override
  Future<NoteAttachment> addAttachment(
      String noteId, NoteAttachment attachment) async {
    final note = _noteStore[noteId];
    if (note != null) {
      final updatedAttachments = List<NoteAttachment>.from(note.attachments)
        ..add(attachment);
      _noteStore[note.id] = note.copyWith(attachments: updatedAttachments);
    }
    return attachment;
  }

  @override
  Future<void> cacheNotesLocally(List<SmartNote> notes) async {
    for (final note in notes) {
      _noteStore[note.id] = note;
    }
  }
}
