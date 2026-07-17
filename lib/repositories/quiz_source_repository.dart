import '../models/quiz_source.dart';
import 'impl/hive_quiz_source_repository.dart';

abstract class QuizSourceRepository {
  static QuizSourceRepository? _instance;

  static QuizSourceRepository get instance {
    _instance ??= HiveQuizSourceRepository();
    return _instance!;
  }

  static set instance(QuizSourceRepository mock) {
    _instance = mock;
  }

  factory QuizSourceRepository() => instance;

  Future<void> saveSource(QuizSource source);
  Future<List<QuizSource>> getSources();
  Future<void> updateSource(QuizSource source);
  Future<void> deleteSource(String id);
  Future<void> toggleFavorite(String id);
}
