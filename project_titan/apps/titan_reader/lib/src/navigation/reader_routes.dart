/// Route path constants for TITAN Reader.
abstract class ReaderRoutes {
  static const String library = '/';
  static const String reader = '/reader';

  /// Builds the reader route path for [documentId].
  static String readerFor(String documentId) => '$reader/$documentId';
}
