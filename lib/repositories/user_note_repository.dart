import '../models/user_note.dart';

abstract class UserNoteRepository {
  Future<UserNote?> getNoteForQuestion(String questionId);
  Future<void> saveNote(UserNote note);
  Future<void> deleteNote(String noteId);
  Future<List<UserNote>> getAllNotes();
  Future<List<UserNote>> searchNotes(String query);
  Future<void> clear();
}
