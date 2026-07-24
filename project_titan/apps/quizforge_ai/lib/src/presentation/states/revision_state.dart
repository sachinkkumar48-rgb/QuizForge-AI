import 'package:meta/meta.dart';
import 'package:titan_revision/titan_revision.dart';

/// Execution status for the Adaptive Revision Engine state.
enum RevisionStateStatus {
  initial,
  loading,
  success,
  error,
}

/// Immutable state container for the Adaptive Revision UI.
@immutable
class RevisionState {
  final RevisionStateStatus status;
  final RevisionQueue? queue;
  final Map<String, double> topicMastery;
  final String selectedCategory;
  final String filterOption;
  final String? errorMessage;

  RevisionState({
    required this.status,
    this.queue,
    Map<String, double>? topicMastery,
    this.selectedCategory = 'All',
    this.filterOption = 'All',
    this.errorMessage,
  }) : topicMastery =
            Map<String, double>.unmodifiable(topicMastery ?? const {});

  const RevisionState.initial()
      : status = RevisionStateStatus.initial,
        queue = null,
        topicMastery = const {},
        selectedCategory = 'All',
        filterOption = 'All',
        errorMessage = null;

  const RevisionState.loading()
      : status = RevisionStateStatus.loading,
        queue = null,
        topicMastery = const {},
        selectedCategory = 'All',
        filterOption = 'All',
        errorMessage = null;

  RevisionState copyWith({
    RevisionStateStatus? status,
    RevisionQueue? queue,
    Map<String, double>? topicMastery,
    String? selectedCategory,
    String? filterOption,
    String? errorMessage,
  }) {
    return RevisionState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      topicMastery: topicMastery ?? this.topicMastery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      filterOption: filterOption ?? this.filterOption,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isInitial => status == RevisionStateStatus.initial;
  bool get isLoading => status == RevisionStateStatus.loading;
  bool get isSuccess => status == RevisionStateStatus.success;
  bool get isError => status == RevisionStateStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          queue == other.queue &&
          selectedCategory == other.selectedCategory &&
          filterOption == other.filterOption &&
          errorMessage == other.errorMessage &&
          _mapEquals(topicMastery, other.topicMastery);

  @override
  int get hashCode => Object.hash(
        status,
        queue,
        selectedCategory,
        filterOption,
        errorMessage,
        Object.hashAll(topicMastery.entries),
      );
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}
