import '../models/editorial_models.dart';

/// Abstract repository interface for persisting editorial records, version history, and audit logs.
abstract class EditorialRepository {
  Future<void> saveRecord(EditorialAssetRecord record);
  Future<EditorialAssetRecord?> getRecordById(String id);
  Future<List<EditorialAssetRecord>> getAllRecords(
      {EditorialStatus? statusFilter});
  Future<void> deleteRecord(String id);
  Future<void> clearAll();
}
