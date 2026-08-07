import '../models/lesson_model.dart';
import 'json_lesson_loader.dart';

class LessonRepository {
  final JsonLessonLoader _jsonLessonLoader;

  LessonRepository({JsonLessonLoader? jsonLessonLoader})
      : _jsonLessonLoader = jsonLessonLoader ?? JsonLessonLoader();

  /// Fetches a lesson by its ID using [JsonLessonLoader] from asset JSON files.
  Future<LessonModel> getLessonById(String lessonId) async {
    return await _jsonLessonLoader.loadLesson(lessonId);
  }

  /// Fetches the manifest listing of all available micro-lessons.
  Future<List<Map<String, String>>> getLessonManifest() async {
    return await _jsonLessonLoader.loadManifest();
  }
}
