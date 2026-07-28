import '../models/authoring_models.dart';
import 'content_authoring_repository.dart';

class ContentAuthoringRepositoryImpl implements ContentAuthoringRepository {
  final Map<String, KmpAuthoringItem> _store = {};

  ContentAuthoringRepositoryImpl() {
    final sample = KmpAuthoringItem(
      id: 'auth_polity_art21',
      title: 'Article 21: Right to Life and Personal Liberty Draft',
      description:
          'Comprehensive analysis including Maneka Gandhi case landmark rulings.',
      format: AuthoringFormat.markdown,
      bodyContent:
          '# Article 21 Analysis\n\nProtection of Life and Personal Liberty...',
      authorId: 'author_editor_1',
      authorName: 'UPSC Subject Matter Expert',
      learningObjectives: [
        'Understand statutory scope of Article 21',
        'Analyze judicial expansion of right to privacy and dignified life'
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[sample.id] = sample;
  }

  @override
  Future<List<KmpAuthoringItem>> getAllAuthoringItems(
      {PublicationStatus? status}) async {
    if (status == null) return _store.values.toList();
    return _store.values.where((item) => item.status == status).toList();
  }

  @override
  Future<KmpAuthoringItem?> getItemById(String id) async {
    return _store[id];
  }

  @override
  Future<KmpAuthoringItem> saveDraft(KmpAuthoringItem item) async {
    _store[item.id] = item;
    return item;
  }

  @override
  Future<KmpAuthoringItem> updateStatus(
    String id,
    PublicationStatus newStatus, {
    String? reviewerId,
  }) async {
    final existing = _store[id];
    if (existing == null) {
      throw Exception('Authoring item not found: $id');
    }
    final updated = existing.copyWith(
      status: newStatus,
      reviewerId: reviewerId ?? existing.reviewerId,
      updatedAt: DateTime.now(),
    );
    _store[id] = updated;
    return updated;
  }

  @override
  Future<void> deleteItem(String id) async {
    _store.remove(id);
  }
}
