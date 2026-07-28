import '../models/notes_models.dart';

/// Clean Architecture abstract repository interface for Smart Notes Engine.
abstract class NotesRepository {
  /// Fetches note by ID.
  Future<SmartNote?> getNoteById(String noteId);

  /// Retrieves notes by collection ID.
  Future<List<SmartNote>> getNotesByCollection(String collectionId);

  /// Retrieves notes associated with a specific content ID (e.g. video or PDF).
  Future<List<SmartNote>> getNotesByContent(String contentId);

  /// Retrieves all cached notes for offline access.
  Future<List<SmartNote>> getAllNotes();

  /// Creates a new smart note.
  Future<SmartNote> createNote(SmartNote note);

  /// Updates an existing smart note and records version history.
  Future<SmartNote> updateNote(SmartNote note);

  /// Deletes a smart note by ID.
  Future<bool> deleteNote(String noteId);

  /// Retrieves version history for a note.
  Future<List<NoteVersion>> getVersionHistory(String noteId);

  /// Adds a bookmark to a note.
  Future<NoteBookmark> addBookmark(NoteBookmark bookmark);

  /// Adds an attachment to a note.
  Future<NoteAttachment> addAttachment(
      String noteId, NoteAttachment attachment);

  /// Caches notes locally for offline usage.
  Future<void> cacheNotesLocally(List<SmartNote> notes);
}
