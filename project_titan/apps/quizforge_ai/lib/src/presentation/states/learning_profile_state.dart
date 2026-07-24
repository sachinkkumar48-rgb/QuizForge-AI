import 'package:meta/meta.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';

enum LearningProfileStatus { initial, loading, success, error }

/// Immutable state container for [LearningProfileController].
@immutable
class LearningProfileState {
  final LearningProfileStatus status;
  final LearningProfile? profile;
  final String? errorMessage;

  const LearningProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  const LearningProfileState.initial()
      : status = LearningProfileStatus.initial,
        profile = null,
        errorMessage = null;

  bool get isLoading => status == LearningProfileStatus.loading;
  bool get isSuccess => status == LearningProfileStatus.success;
  bool get isError => status == LearningProfileStatus.error;

  LearningProfileState copyWith({
    LearningProfileStatus? status,
    LearningProfile? profile,
    String? errorMessage,
  }) {
    return LearningProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProfileState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          profile == other.profile &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, profile, errorMessage);
}
