import '../models/dataset_manifest.dart';

abstract class DatasetRepository {
  Future<void> saveManifest(DatasetManifest manifest);
  Future<DatasetManifest?> getManifest(String datasetId);
  Future<List<DatasetManifest>> getAllManifests();
  Future<void> deleteManifest(String datasetId);
  Future<void> clear();
}
