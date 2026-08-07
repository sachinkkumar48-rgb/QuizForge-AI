import '../entities/enums.dart';
import '../entities/evidence_object.dart';
import '../entities/knowledge_object_links.dart';
import '../repositories/evidence_repository.dart';

/// Use case for linking an EvidenceObject to GARUDA Knowledge Graph objects.
class LinkKnowledgeObjectUseCase {
  final EvidenceRepository repository;

  LinkKnowledgeObjectUseCase(this.repository);

  Future<EvidenceObject?> call({
    required String evidenceId,
    required KnowledgeObjectType type,
    required String targetLinkId,
  }) async {
    final evidence = await repository.findById(evidenceId);
    if (evidence == null) return null;

    final currentLinks = evidence.knowledgeObjectLinks;
    KnowledgeObjectLinks updatedLinks;

    switch (type) {
      case KnowledgeObjectType.constitutionArticles:
        updatedLinks = currentLinks.copyWith(
          constitutionArticles: [...currentLinks.constitutionArticles, targetLinkId],
        );
        break;
      case KnowledgeObjectType.caseLaws:
        updatedLinks = currentLinks.copyWith(
          caseLaws: [...currentLinks.caseLaws, targetLinkId],
        );
        break;
      case KnowledgeObjectType.acts:
        updatedLinks = currentLinks.copyWith(
          acts: [...currentLinks.acts, targetLinkId],
        );
        break;
      case KnowledgeObjectType.amendments:
        updatedLinks = currentLinks.copyWith(
          amendments: [...currentLinks.amendments, targetLinkId],
        );
        break;
      case KnowledgeObjectType.committees:
        updatedLinks = currentLinks.copyWith(
          committees: [...currentLinks.committees, targetLinkId],
        );
        break;
      case KnowledgeObjectType.reports:
        updatedLinks = currentLinks.copyWith(
          reports: [...currentLinks.reports, targetLinkId],
        );
        break;
      case KnowledgeObjectType.schemes:
        updatedLinks = currentLinks.copyWith(
          schemes: [...currentLinks.schemes, targetLinkId],
        );
        break;
      case KnowledgeObjectType.people:
        updatedLinks = currentLinks.copyWith(
          people: [...currentLinks.people, targetLinkId],
        );
        break;
      case KnowledgeObjectType.institutions:
        updatedLinks = currentLinks.copyWith(
          institutions: [...currentLinks.institutions, targetLinkId],
        );
        break;
      case KnowledgeObjectType.lessons:
        updatedLinks = currentLinks.copyWith(
          lessons: [...currentLinks.lessons, targetLinkId],
        );
        break;
      case KnowledgeObjectType.pyqs:
        updatedLinks = currentLinks.copyWith(
          pyqs: [...currentLinks.pyqs, targetLinkId],
        );
        break;
      case KnowledgeObjectType.maps:
        updatedLinks = currentLinks.copyWith(
          maps: [...currentLinks.maps, targetLinkId],
        );
        break;
      case KnowledgeObjectType.timeline:
        updatedLinks = currentLinks.copyWith(
          timeline: [...currentLinks.timeline, targetLinkId],
        );
        break;
      case KnowledgeObjectType.currentAffairs:
        updatedLinks = currentLinks.copyWith(
          currentAffairs: [...currentLinks.currentAffairs, targetLinkId],
        );
        break;
    }

    final updatedEvidence = evidence.copyWith(
      knowledgeObjectLinks: updatedLinks,
      updatedAt: DateTime.now(),
    );

    await repository.update(updatedEvidence);
    return updatedEvidence;
  }
}
