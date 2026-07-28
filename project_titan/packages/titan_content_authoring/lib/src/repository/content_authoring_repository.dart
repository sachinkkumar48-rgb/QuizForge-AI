import '../models/authoring_models.dart';

abstract class ContentAuthoringRepository {
  Future<List<KmpAuthoringItem>> getAllAuthoringItems(
      {PublicationStatus? status});
  Future<KmpAuthoringItem?> getItemById(String id);
  Future<KmpAuthoringItem> saveDraft(KmpAuthoringItem item);
  Future<KmpAuthoringItem> updateStatus(String id, PublicationStatus newStatus,
      {String? reviewerId});
  Future<void> deleteItem(String id);
}
