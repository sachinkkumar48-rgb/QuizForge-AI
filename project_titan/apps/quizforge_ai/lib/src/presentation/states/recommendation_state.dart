import 'package:meta/meta.dart';
import 'package:titan_recommendation/titan_recommendation.dart';

enum RecommendationStatus { initial, loading, success, error }

/// Immutable state container for [RecommendationController].
@immutable
class RecommendationState {
  final RecommendationStatus status;
  final List<Recommendation> recommendations;
  final String? errorMessage;

  const RecommendationState({
    required this.status,
    required this.recommendations,
    this.errorMessage,
  });

  const RecommendationState.initial()
      : status = RecommendationStatus.initial,
        recommendations = const [],
        errorMessage = null;

  bool get isLoading => status == RecommendationStatus.loading;
  bool get isSuccess => status == RecommendationStatus.success;
  bool get isError => status == RecommendationStatus.error;

  RecommendationState copyWith({
    RecommendationStatus? status,
    List<Recommendation>? recommendations,
    String? errorMessage,
  }) {
    return RecommendationState(
      status: status ?? this.status,
      recommendations: recommendations ?? this.recommendations,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          _listEquals(recommendations, other.recommendations);

  @override
  int get hashCode =>
      Object.hash(status, errorMessage, Object.hashAll(recommendations));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
