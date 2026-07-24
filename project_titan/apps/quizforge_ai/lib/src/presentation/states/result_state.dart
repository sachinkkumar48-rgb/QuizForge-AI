import 'package:meta/meta.dart';
import 'package:titan_analytics/titan_analytics.dart';

/// Execution status for the Intelligent Results Dashboard workflow state.
enum ResultStateStatus {
  initial,
  loading,
  success,
  error,
}

/// Immutable state container for the Intelligent Results Dashboard UI.
@immutable
class ResultState {
  final ResultStateStatus status;
  final ResultAnalytics? analytics;
  final String? errorMessage;

  const ResultState({
    required this.status,
    this.analytics,
    this.errorMessage,
  });

  const ResultState.initial()
      : status = ResultStateStatus.initial,
        analytics = null,
        errorMessage = null;

  const ResultState.loading()
      : status = ResultStateStatus.loading,
        analytics = null,
        errorMessage = null;

  const ResultState.success(ResultAnalytics analytics)
      : status = ResultStateStatus.success,
        analytics = analytics,
        errorMessage = null;

  const ResultState.error(String message)
      : status = ResultStateStatus.error,
        analytics = null,
        errorMessage = message;

  bool get isInitial => status == ResultStateStatus.initial;
  bool get isLoading => status == ResultStateStatus.loading;
  bool get isSuccess => status == ResultStateStatus.success;
  bool get isError => status == ResultStateStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          analytics == other.analytics &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, analytics, errorMessage);
}
