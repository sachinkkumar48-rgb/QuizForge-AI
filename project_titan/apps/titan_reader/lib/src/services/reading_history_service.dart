import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/reading_visit.dart';

/// Service maintaining the ordered reading history (recent documents).
///
/// The history is a bounded list of visits, most recent first. A document
/// appears at most once: re-visiting moves its entry to the front with the
/// new timestamp. The list is capped at [maxEntries].
class ReadingHistoryService {
  /// Maximum number of history entries retained.
  static const int maxEntries = 50;

  /// Storage namespace used for the reading history.
  static const String namespace = 'titan.reader.history';

  /// Storage key holding the serialized history.
  static const String historyKey = 'visits';

  final StorageService _storage;

  ReadingHistoryService(this._storage);

  StorageKey get _key => const StorageKey(historyKey, namespace: namespace);

  /// Records a visit to [documentId] at [visitedAt].
  Future<void> recordVisit({
    required String documentId,
    required DateTime visitedAt,
  }) async {
    final visit = ReadingVisit(documentId: documentId, visitedAt: visitedAt);
    final visits = await getVisits();
    visits.removeWhere((v) => v.documentId == documentId);
    visits.insert(0, visit);
    final capped =
        visits.length > maxEntries ? visits.sublist(0, maxEntries) : visits;
    final payload =
        jsonEncode(capped.map((v) => v.toJson()).toList(growable: false));
    await _storage.write<String>(_key, payload);
  }

  /// Returns the stored visits, most recent first.
  Future<List<ReadingVisit>> getVisits() async {
    final raw = await _storage.read<String>(_key);
    if (raw == null || raw.isEmpty) return <ReadingVisit>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException(
          'Reading history is malformed: expected JSON list.');
    }
    final result = <ReadingVisit>[];
    for (final item in decoded) {
      if (item is Map<String, Object?>) {
        try {
          result.add(ReadingVisit.fromJson(item));
        } on FormatException {
          continue;
        }
      }
    }
    return result;
  }

  /// Returns recent document ids, most recent first.
  Future<List<String>> recentDocumentIds() async {
    final visits = await getVisits();
    return visits.map((v) => v.documentId).toList(growable: false);
  }

  /// Removes any history entry for [documentId].
  Future<void> removeDocument(String documentId) async {
    final visits = await getVisits();
    visits.removeWhere((v) => v.documentId == documentId);
    final payload =
        jsonEncode(visits.map((v) => v.toJson()).toList(growable: false));
    await _storage.write<String>(_key, payload);
  }
}
