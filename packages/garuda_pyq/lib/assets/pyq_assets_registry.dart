import '../models/exam_model.dart';

class PYQAssetsRegistry {
  static final Map<String, String> _examDatasetAssetPaths = {
    SupportedExam.upscCse.id: 'assets/datasets/upsc/prelims/gs1/',
    SupportedExam.bpsc.id: 'assets/datasets/bpsc/70th/',
  };

  static String? getDatasetPathForExam(String examId) {
    return _examDatasetAssetPaths[examId];
  }

  static void registerAssetPath(String examId, String assetPath) {
    _examDatasetAssetPaths[examId] = assetPath;
  }
}
