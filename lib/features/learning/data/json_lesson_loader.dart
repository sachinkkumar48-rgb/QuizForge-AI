import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lesson_model.dart';

/// Service responsible for loading lesson JSON content from Flutter assets
/// and deserializing it into [LessonModel].
class JsonLessonLoader {
  final AssetBundle _assetBundle;

  JsonLessonLoader({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  /// Mapping of lesson IDs to asset resource paths.
  static const Map<String, String> _lessonAssetMap = {
    'POL.FR.001': 'assets/content/polity/fundamental_rights/POL.FR.001.json',
    'POL-FR-001': 'assets/content/polity/fundamental_rights/POL.FR.001.json',
    'POL.FR.002': 'assets/content/polity/fundamental_rights/POL.FR.002.json',
    'POL-FR-002': 'assets/content/polity/fundamental_rights/POL.FR.002.json',
  };

  /// Manifest asset path.
  static const String manifestAssetPath = 'assets/content/content_manifest.json';

  /// Loads lesson JSON from assets by lesson ID and deserializes it into [LessonModel].
  Future<LessonModel> loadLesson(String lessonId) async {
    String? assetPath = _lessonAssetMap[lessonId];
    if (assetPath == null) {
      final manifest = await loadManifest();
      final lessonMeta = manifest.firstWhere(
        (item) => item['id'] == lessonId || item['id']?.replaceAll('.', '-') == lessonId,
        orElse: () => <String, String>{},
      );
      if (lessonMeta.containsKey('assetPath')) {
        assetPath = lessonMeta['assetPath'];
      }
    }

    assetPath ??= 'assets/content/polity/fundamental_rights/POL.FR.001.json';
    return await loadLessonFromPath(assetPath);
  }

  /// Loads lesson JSON from a specific asset path and deserializes it into [LessonModel].
  Future<LessonModel> loadLessonFromPath(String assetPath) async {
    final jsonString = await _assetBundle.loadString(assetPath);
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return LessonModel.fromJson(jsonMap);
  }

  /// Loads the content manifest listing all registered lessons.
  Future<List<Map<String, String>>> loadManifest() async {
    try {
      final manifestString = await _assetBundle.loadString(manifestAssetPath);
      final Map<String, dynamic> manifestJson = json.decode(manifestString) as Map<String, dynamic>;
      final lessons = manifestJson['lessons'] as List<dynamic>?;
      if (lessons != null) {
        return lessons.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'id': map['id'].toString(),
            'title': map['title'].toString(),
            'subject': map['subject'].toString(),
            'estimatedTime': map['estimatedTime'].toString(),
            'difficulty': map['difficulty']?.toString() ?? 'Intermediate',
            'assetPath': map['assetPath'].toString(),
          };
        }).toList();
      }
    } catch (_) {
      // Fallback if manifest is not found or fails to load
    }
    return [
      {
        'id': 'POL.FR.001',
        'title': 'Why Fundamental Rights?',
        'subject': 'Indian Polity',
        'estimatedTime': '15 Minutes',
        'assetPath': 'assets/content/polity/fundamental_rights/POL.FR.001.json',
      },
      {
        'id': 'POL.FR.002',
        'title': 'Articles 12 & 13: Definition of State & Judicial Review',
        'subject': 'Indian Polity',
        'estimatedTime': '20 Minutes',
        'assetPath': 'assets/content/polity/fundamental_rights/POL.FR.002.json',
      },
    ];
  }
}
