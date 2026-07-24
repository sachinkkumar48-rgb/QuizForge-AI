import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_core/titan_core.dart';
import '../../coordinator/application_coordinator.dart';
import '../../states/application_state.dart';

/// Provider exposing the global [ApplicationCoordinator] from [TitanServiceLocator].
final applicationCoordinatorProvider = Provider<ApplicationCoordinator>((ref) {
  return TitanServiceLocator.instance.get<ApplicationCoordinator>();
});

/// Notifier providing UI access to immutable [ApplicationState].
class ApplicationStateNotifier extends Notifier<ApplicationState> {
  @override
  ApplicationState build() {
    try {
      final coordinator = ref.watch(applicationCoordinatorProvider);
      return coordinator.state;
    } catch (_) {
      return const ApplicationState.idle();
    }
  }

  /// Syncs state from coordinator.
  void updateState() {
    try {
      final coordinator = ref.read(applicationCoordinatorProvider);
      state = coordinator.state;
    } catch (_) {
      state = const ApplicationState.idle();
    }
  }
}

/// Provider exposing current [ApplicationState].
final applicationStateProvider =
    NotifierProvider<ApplicationStateNotifier, ApplicationState>(
        ApplicationStateNotifier.new);
