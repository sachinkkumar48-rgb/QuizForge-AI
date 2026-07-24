import 'package:flutter/foundation.dart';
import '../models/analytics_engine_models.dart';
import '../models/pyq_question_model.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/impl/hive_analytics_repository.dart';
import '../services/analytics_exporter.dart';
import '../services/analytics_service.dart';

/// State controller bridging UI, AnalyticsRepository, and AnalyticsService.
class AnalyticsController extends ChangeNotifier {
  final AnalyticsRepository repository;
  final AnalyticsService service;

  LearningInsightsModel? _insights;
  List<AnalyticsSnapshot> _historicalSnapshots = [];
  bool _isLoading = false;
  String _errorMessage = '';

  AnalyticsController({
    AnalyticsRepository? repository,
    AnalyticsService? service,
  })  : repository = repository ?? HiveAnalyticsRepository(),
        service = service ?? AnalyticsService();

  // Getters
  LearningInsightsModel? get insights => _insights;
  List<AnalyticsSnapshot> get historicalSnapshots =>
      List.unmodifiable(_historicalSnapshots);
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasData => _insights != null;

  /// Load questions, calculate full insights, and refresh historical snapshots.
  Future<void> loadAnalytics(List<PyqQuestionModel> questions) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _insights = service.computeLearningInsights(questions);
      _historicalSnapshots = await repository.getSnapshots();

      // Automatically record a snapshot if not recorded today
      if (_insights != null) {
        final latest = await repository.getLatestSnapshot();
        final now = DateTime.now();
        final isToday = latest != null &&
            latest.timestamp.year == now.year &&
            latest.timestamp.month == now.month &&
            latest.timestamp.day == now.day;

        if (!isToday) {
          final newSnapshot = service.createSnapshot(_insights!);
          await repository.saveSnapshot(newSnapshot);
          _historicalSnapshots = await repository.getSnapshots();
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create and persist a manual performance snapshot.
  Future<void> captureSnapshot() async {
    if (_insights == null) return;
    try {
      final snapshot = service.createSnapshot(_insights!);
      await repository.saveSnapshot(snapshot);
      _historicalSnapshots = await repository.getSnapshots();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Export current insights to JSON format.
  String exportJson() {
    if (_insights == null) return '{}';
    return AnalyticsExporter.exportToJson(_insights!);
  }

  /// Export current insights to CSV format.
  String exportCsv() {
    if (_insights == null) return '';
    return AnalyticsExporter.exportToCsv(_insights!);
  }

  /// Export current insights to printable PDF / Text report.
  String exportPdfReport() {
    if (_insights == null) return '';
    return AnalyticsExporter.exportToPdfTextReport(_insights!);
  }
}
