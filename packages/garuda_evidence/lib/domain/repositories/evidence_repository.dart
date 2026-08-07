import '../entities/evidence_object.dart';
import '../entities/evidence_search_query.dart';

/// Repository interface contract for persistence and retrieval of Evidence Objects.
abstract class EvidenceRepository {
  /// Save a new EvidenceObject. Returns true if successful.
  Future<bool> save(EvidenceObject evidence);

  /// Update an existing EvidenceObject. Returns true if updated successfully.
  Future<bool> update(EvidenceObject evidence);

  /// Delete an EvidenceObject by its unique identifier.
  Future<bool> delete(String id);

  /// Retrieve an EvidenceObject by ID. Returns null if not found.
  Future<EvidenceObject?> findById(String id);

  /// Find all evidence objects originating from a specified source name.
  Future<List<EvidenceObject>> findBySource(String sourceName);

  /// Find all evidence objects associated with a specific topic.
  Future<List<EvidenceObject>> findByTopic(String topic);

  /// Find all evidence objects tagged with a specific tag name.
  Future<List<EvidenceObject>> findByTag(String tag);

  /// Find the most recent evidence objects sorted by publication or retrieval date.
  Future<List<EvidenceObject>> findRecent({int limit = 10});

  /// Execute a search across 8 search vectors using [EvidenceSearchQuery].
  Future<List<EvidenceObject>> search(EvidenceSearchQuery query);
}
