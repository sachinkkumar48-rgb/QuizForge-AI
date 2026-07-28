import '../models/media_models.dart';
import 'media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final Map<String, KmpMediaAsset> _assets = {};

  MediaRepositoryImpl() {
    final sampleVideo = KmpMediaAsset(
      id: 'media_v_polity_21',
      filename: 'article_21_lecture.mp4',
      title: 'Article 21 Constitutional Breakdown Video',
      type: KmpMediaType.video,
      remoteStorageUrl: 'https://cdn.titan.org/video/article_21_lecture.mp4',
      metadata: const MediaMetadata(
        fileSizeBytes: 45200100,
        mimeType: 'video/mp4',
        widthPixels: 1920,
        heightPixels: 1080,
        durationSeconds: 2700,
        encodingCodec: 'H.264 / AAC',
      ),
      uploadedBy: 'media_admin',
      uploadedAt: DateTime.now(),
    );

    _assets[sampleVideo.id] = sampleVideo;
  }

  @override
  Future<List<KmpMediaAsset>> getMediaAssets({KmpMediaType? type}) async {
    if (type == null) return _assets.values.toList();
    return _assets.values.where((a) => a.type == type).toList();
  }

  @override
  Future<KmpMediaAsset?> getMediaById(String id) async {
    return _assets[id];
  }

  @override
  Future<KmpMediaAsset> uploadMediaAsset(KmpMediaAsset asset) async {
    _assets[asset.id] = asset;
    return asset;
  }

  @override
  Future<void> deleteMediaAsset(String id) async {
    _assets.remove(id);
  }
}
