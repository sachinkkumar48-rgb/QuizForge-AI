import '../entities/evidence_object.dart';
import '../entities/evidence_search_query.dart';
import '../repositories/evidence_repository.dart';

/// Use case for executing structured multi-vector search queries on Evidence Objects.
class SearchEvidenceUseCase {
  final EvidenceRepository repository;

  SearchEvidenceUseCase(this.repository);

  Future<List<EvidenceObject>> call(EvidenceSearchQuery query) async {
    return await repository.search(query);
  }
}
