import 'package:flutter/material.dart';

import '../../controllers/dashboard_state.dart';

/// Plugin Module Grid Widget displaying active exam modules in M3 design.
class PluginModuleGridWidget extends StatelessWidget {
  final List<DashboardModuleInfo> modules;
  final VoidCallback? onExploreTap;

  const PluginModuleGridWidget({
    super.key,
    required this.modules,
    this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Exam Modules",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: onExploreTap,
              child: const Text("Explore All"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (modules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("No plugin modules loaded."),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: modules.take(6).map((mod) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    avatar: Icon(
                      mod.isEnabled
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16,
                      color: mod.isEnabled ? Colors.green : Colors.grey,
                    ),
                    label: Text("${mod.title} (${mod.category})"),
                    selected: mod.isEnabled,
                    onSelected: (_) {},
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
