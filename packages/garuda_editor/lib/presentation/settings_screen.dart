import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';
import '../domain/entities/editorial_role.dart';

/// Module 8: Settings and prepared Role Permissions matrix for GARUDA Editorial Studio.
class SettingsScreen extends StatelessWidget {
  final EditorialStudioController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editorial Workspace Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure workspace roles, UI themes, and permission matrices.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Editor Role Simulator', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Select an active role to simulate permissions across studio workflows.'),
                  const SizedBox(height: 16),

                  SegmentedButton<EditorialRole>(
                    segments: EditorialRole.values
                        .map((r) => ButtonSegment<EditorialRole>(
                              value: r,
                              label: Text(r.label),
                            ))
                        .toList(),
                    selected: {controller.currentRole},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) {
                        controller.setRole(set.first);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Role Permissions Reference Matrix
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Role Permissions Matrix', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Capability')),
                      DataColumn(label: Text('Editor')),
                      DataColumn(label: Text('Senior Editor')),
                      DataColumn(label: Text('Reviewer')),
                      DataColumn(label: Text('Admin')),
                    ],
                    rows: const [
                      DataRow(cells: [
                        DataCell(Text('Create / Edit Draft KOs')),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                        DataCell(Icon(Icons.close, color: Colors.red)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Review Evidence & Links')),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Approve Publishing Queue')),
                        DataCell(Icon(Icons.close, color: Colors.red)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                        DataCell(Icon(Icons.close, color: Colors.red)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Manage Workspace Settings')),
                        DataCell(Icon(Icons.close, color: Colors.red)),
                        DataCell(Icon(Icons.close, color: Colors.red)),
                        DataCell(Icon(Icons.close, color: Colors.red)),
                        DataCell(Icon(Icons.check, color: Colors.green)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
