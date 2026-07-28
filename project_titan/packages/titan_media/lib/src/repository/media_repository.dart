import '../models/media_models.dart';

abstract class MediaRepository {
  Future<List<KmpMediaAsset>> getMediaAssets({KmpMediaType? type});
  Future<KmpMediaAsset?> getMediaById(String id);
  Future<KmpMediaAsset> uploadMediaAsset(KmpMediaAsset asset);
  Future<void> deleteMediaAsset(String id);
}
