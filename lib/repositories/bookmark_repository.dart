import '../models/bookmark.dart';

abstract class BookmarkRepository {
  Future<void> toggleBookmark(String questionId,
      {String category = 'General', String? noteSnippet});
  Future<bool> isBookmarked(String questionId);
  Future<Bookmark?> getBookmark(String questionId);
  Future<List<Bookmark>> getBookmarks();
  Future<List<String>> getBookmarkedQuestionIds();
  Future<void> removeBookmark(String questionId);
  Future<void> clear();
}
