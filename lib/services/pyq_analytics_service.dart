import '../models/pyq_analytics_model.dart';
import '../models/pyq_question_model.dart';
import 'analytics_engine.dart';

class PyqAnalyticsService {
  PyqAnalyticsService._();

  static PyqAnalyticsModel computeAnalytics(List<PyqQuestionModel> questions) {
    return AnalyticsEngine.computeFullAnalytics(questions);
  }
}
