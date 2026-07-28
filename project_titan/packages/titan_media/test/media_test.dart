import 'package:flutter_test/flutter_test.dart';
import 'package:titan_media/titan_media.dart';

void main() {
  group('Media Library Unit Tests', () {
    late MediaRepository repository;

    setUp(() {
      repository = MediaRepositoryImpl();
    });

    test('getMediaAssets returns seeded video asset', () async {
      final assets = await repository.getMediaAssets(type: KmpMediaType.video);
      expect(assets.isNotEmpty, isTrue);
      expect(assets.first.metadata.durationSeconds, equals(2700));
    });

    test('uploadMediaAsset adds new PDF infographic', () async {
      final infographic = KmpMediaAsset(
        id: 'media_info_1',
        filename: 'fundamental_rights_mindmap.png',
        title: 'Fundamental Rights Chart',
        type: KmpMediaType.infographic,
        remoteStorageUrl: 'https://cdn.titan.org/images/fr_chart.png',
        metadata: const MediaMetadata(
          fileSizeBytes: 2048000,
          mimeType: 'image/png',
          widthPixels: 3840,
          heightPixels: 2160,
        ),
        uploadedBy: 'graphics_team',
        uploadedAt: DateTime.now(),
      );

      await repository.uploadMediaAsset(infographic);
      final fetched = await repository.getMediaById('media_info_1');
      expect(fetched, isNotNull);
      expect(fetched!.type, equals(KmpMediaType.infographic));
    });
  });
}
