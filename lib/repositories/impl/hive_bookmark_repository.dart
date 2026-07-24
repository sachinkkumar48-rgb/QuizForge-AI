import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/bookmark.dart';
import '../bookmark_repository.dart';

class HiveBookmarkRepository implements BookmarkRepository {
  static const String _boxName = 'engine_bookmarks';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<void> toggleBookmark(
    String questionId, {
    String category = 'General',
    String? noteSnippet,
  }) async {
    final box = await _getBox();
    if (box.containsKey(questionId)) {
      await box.delete(questionId);
    } else {
      final bookmark = Bookmark(
        bookmarkId: questionId,
        questionId: questionId,
        category: category,
        noteSnippet: noteSnippet,
      );
      await box.put(questionId, jsonEncode(bookmark.toJson()));
    }
  }

  @override
  Future<bool> isBookmarked(String questionId) async {
    final box = await _getBox();
    return box.containsKey(questionId);
  }

  @override
  Future<Bookmark?> getBookmark(String questionId) async {
    final box = await _getBox();
    final jsonStr = box.get(questionId);
    if (jsonStr == null) return null;
    try {
      return Bookmark.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks() async {
    final box = await _getBox();
    final List<Bookmark> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(Bookmark.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<String>> getBookmarkedQuestionIds() async {
    final bookmarks = await getBookmarks();
    return bookmarks.map((b) => b.questionId).toList();
  }

  @override
  Future<void> removeBookmark(String questionId) async {
    final box = await _getBox();
    await box.delete(questionId);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
