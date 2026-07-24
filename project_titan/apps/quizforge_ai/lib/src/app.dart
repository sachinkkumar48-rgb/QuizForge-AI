import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'coordinator/application_coordinator.dart';
import 'presentation/localization/app_localization.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/theme/app_theme.dart';

/// Main Flutter presentation entry widget for QuizForge AI.
class QuizForgeApp extends StatelessWidget {
  final ApplicationCoordinator? coordinator;

  const QuizForgeApp({
    super.key,
    this.coordinator,
  });

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: QuizForgeAppView(),
    );
  }
}

/// Root ConsumerWidget configuring MaterialApp.router.
class QuizForgeAppView extends ConsumerWidget {
  const QuizForgeAppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppLocalization.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
