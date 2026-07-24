import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/user_note.dart';
import '../user_note_repository.dart';

class HiveUserNoteRepository implements UserNoteRepository {
  static const String _boxName = 'engine_user_notes';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<UserNote?> getNoteForQuestion(String questionId) async {
    final box = await _getBox();
    final jsonStr = box.get(questionId);
    if (jsonStr == null) return null;
    try {
      return UserNote.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveNote(UserNote note) async {
    final box = await _getBox();
    await box.put(note.questionId, jsonEncode(note.toJson()));
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final box = await _getBox();
    // Key by questionId or noteId
    if (box.containsKey(noteId)) {
      await box.delete(noteId);
      return;
    }
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final note = UserNote.fromJson(jsonDecode(jsonStr));
          if (note.noteId == noteId) {
            await box.delete(key);
            break;
          }
        } catch (_) {}
      }
    }
  }

  @override
  Future<List<UserNote>> getAllNotes() async {
    final box = await _getBox();
    final List<UserNote> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(UserNote.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<List<UserNote>> searchNotes(String query) async {
    final all = await getAllNotes();
    if (query.trim().isEmpty) return all;
    final qLower = query.trim().toLowerCase();
    return all.where((n) {
      return n.title.toLowerCase().contains(qLower) ||
          n.content.toLowerCase().contains(qLower) ||
          n.tags.any((t) => t.toLowerCase().contains(qLower));
    }).toList();
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
