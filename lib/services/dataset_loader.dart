import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/dataset_manifest.dart';
import '../models/validation_report.dart';
import 'dataset_validator.dart';
import 'generic_dataset_importer.dart';

class DatasetLoader {
  final GenericDatasetImporter importer;
  final AssetBundle? assetBundle;

  static const String datasetsAssetFolder = 'assets/datasets/';

  DatasetLoader({
    required this.importer,
    this.assetBundle,
  });

  AssetBundle get _bundle => assetBundle ?? rootBundle;

  /// Dynamically discover all `dataset.json` asset paths matching `assets/datasets/`
  /// without hardcoding years or exams.
  Future<List<String>> discoverDatasetAssetPaths() async {
    final List<String> datasetPaths = [];
    try {
      final manifestMap = await _loadAssetManifest();
      for (final key in manifestMap.keys) {
        if (key.startsWith(datasetsAssetFolder) && key.endsWith('.json')) {
          datasetPaths.add(key);
        }
      }
    } catch (_) {
      // Gracefully handle unpopulated manifest or testing environment
    }
    datasetPaths.sort();
    return datasetPaths;
  }

  /// Helper to load AssetManifest across Flutter versions
  Future<Map<String, dynamic>> _loadAssetManifest() async {
    try {
      final manifestJson = await _bundle.loadString('AssetManifest.json');
      return jsonDecode(manifestJson) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Discover and parse `DatasetManifest` metadata for all available datasets
  /// without performing database writes.
  Future<List<DatasetManifest>> discoverManifests(
      {List<String>? overridePaths}) async {
    final paths = overridePaths ?? await discoverDatasetAssetPaths();
    final List<DatasetManifest> manifests = [];

    for (final path in paths) {
      try {
        final jsonString = await _bundle.loadString(path);
        final decoded = jsonDecode(jsonString);

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('manifest') && decoded['manifest'] is Map) {
            manifests.add(DatasetManifest.fromJson(
                Map<String, dynamic>.from(decoded['manifest'] as Map)));
          } else if (decoded.containsKey('datasetId')) {
            manifests.add(DatasetManifest.fromJson(decoded));
          }
        }
      } catch (_) {}
    }
    return manifests;
  }

  /// Read, validate, and import a single dataset from asset path.
  Future<int> loadAndImportAsset(
    String assetPath, {
    ImportMode importMode = ImportMode.safe,
  }) async {
    final jsonString = await _bundle.loadString(assetPath);

    // Pre-import validation
    final decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
      final rawQuestions = decoded['questions'] as List;
      final report = DatasetValidator.validateQuestions(rawQuestions);
      if (importMode == ImportMode.strict && report.hasErrors) {
        throw DatasetValidationException(
          'Dataset validation failed for asset $assetPath:\n${report.generateSummaryText()}',
          report,
        );
      }
    }

    return await importer.importDatasetJson(jsonString, importMode: importMode);
  }

  /// Discover, validate, and import all available exam datasets automatically.
  Future<int> loadAndImportAllDiscovered({
    List<String>? overridePaths,
    ImportMode importMode = ImportMode.safe,
  }) async {
    final paths = overridePaths ?? await discoverDatasetAssetPaths();
    int totalImported = 0;

    for (final path in paths) {
      try {
        final count = await loadAndImportAsset(path, importMode: importMode);
        totalImported += count;
      } catch (_) {
        if (importMode == ImportMode.strict) rethrow;
      }
    }

    return totalImported;
  }
}
