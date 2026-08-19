/// Route path constants for TITAN Reader.
abstract class ReaderRoutes {
  static const String library = '/';
  static const String reader = '/reader';
  static const String vocabulary = '/vocabulary';

  /// Builds the reader route path for [documentId], optionally requesting a
  /// specific [page] (used by vocabulary source navigation).
  static String readerFor(String documentId, {int? page}) {
    final base = '$reader/$documentId';
    return page == null ? base : '$base?page=$page';
  }
}
