import '../entities/evidence_object.dart';
import '../repositories/evidence_repository.dart';

/// Use case for persisting an [EvidenceObject] into the [EvidenceRepository].
class StoreEvidenceUseCase {
  final EvidenceRepository repository;

  StoreEvidenceUseCase(this.repository);

  Future<bool> call(EvidenceObject evidence) async {
    final existing = await repository.findById(evidence.id);
    if (existing != null) {
      return await repository.update(evidence);
    } else {
      return await repository.save(evidence);
    }
  }
}
