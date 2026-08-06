import 'dart:convert';

import '../models/question_model.dart';

class JSONIngestion {
  /// Parses JSON string into a list of Question domain models.
  static List<Question> parseQuestionsJson(String jsonString) {
    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Exports list of Question models into formatted JSON string.
  static String exportQuestionsJson(List<Question> questions) {
    final list = questions.map((q) => q.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}
