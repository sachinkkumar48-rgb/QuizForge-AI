library;

import '../domain/entities/news_event.dart';

/// Abstract adapter interface for official government source integrations.
abstract class SourceAdapter {
  String get sourceId;
  String get officialName;
  String get baseUrl;

  /// Fetches/parses official raw payloads into a list of verified [NewsEvent] instances.
  Future<List<NewsEvent>> fetchEvents({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });
}
