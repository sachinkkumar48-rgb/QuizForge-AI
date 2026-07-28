import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';
import 'dashboard_error_view.dart';
import 'dashboard_offline_banner.dart';
import 'dashboard_scroll_view.dart';
import 'dashboard_skeleton.dart';

/// Top-level Home Dashboard widget for Project TITAN.
/// Serves as the primary landing dashboard learners see immediately after login.
class DashboardHome extends ConsumerWidget {
  final String userId;
  final String userName;
  final Function(String route)? onNavigate;

  const DashboardHome({
    super.key,
    required this.userId,
    required this.userName,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      dashboardStateNotifierProvider((userId: userId, userName: userName)),
    );
    final notifier = ref.read(
      dashboardStateNotifierProvider((userId: userId, userName: userName))
          .notifier,
    );

    final customHandler = ref.watch(quickActionHandlerProvider);

    void handleNavigation(String route) {
      if (customHandler != null) {
        customHandler(route);
      } else if (onNavigate != null) {
        onNavigate!(route);
      }
    }

    if (state.isLoading && state.header.displayName == 'Learner') {
      return const Scaffold(
        body: SafeArea(child: DashboardSkeleton()),
      );
    }

    if (state.errorMessage != null &&
        !state.isOffline &&
        state.header.userId.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: DashboardErrorView(
            errorMessage: state.errorMessage!,
            onRetry: () => notifier.load(forceRefresh: true),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (state.isOffline)
              DashboardOfflineBanner(lastUpdated: state.lastUpdated),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await notifier.refresh();
                },
                child: DashboardScrollView(
                  state: state,
                  onActionTap: handleNavigation,
                  onRefresh: () => notifier.refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
