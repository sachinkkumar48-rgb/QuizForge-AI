import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardHome(
      userId: 'user_titan',
      userName: 'UPSC Aspirant',
      onNavigate: (route) {
        context.go(route);
      },
    );
  }
}
