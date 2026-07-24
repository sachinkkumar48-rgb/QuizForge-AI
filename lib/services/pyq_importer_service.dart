import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/pyq_question_model.dart';

class PyqImporterService {
  PyqImporterService._();

  /// Parse structured JSON string into a list of [PyqQuestionModel].
  static List<PyqQuestionModel> parseDatasetJson(String jsonString) {
    if (jsonString.trim().isEmpty) return [];

    final decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      throw FormatException("Expected JSON array at root level.");
    }

    return decoded
        .map(
          (item) => PyqQuestionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Load PYQ dataset from asset path (e.g. `assets/pyq_dataset.json`).
  static Future<List<PyqQuestionModel>> loadAssetDataset({
    String assetPath = "assets/pyq_dataset.json",
  }) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      return parseDatasetJson(jsonString);
    } catch (e) {
      return [];
    }
  }
}
