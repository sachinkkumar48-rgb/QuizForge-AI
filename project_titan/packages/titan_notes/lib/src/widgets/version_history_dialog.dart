import 'package:flutter/material.dart';
import '../models/note_version.dart';

/// Material 3 Version History Dialog component.
class VersionHistoryDialog extends StatelessWidget {
  final List<NoteVersion> versions;
  final ValueChanged<NoteVersion> onRestoreVersion;

  const VersionHistoryDialog({
    super.key,
    required this.versions,
    required this.onRestoreVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Version History'),
      content: SizedBox(
        width: double.maxFinite,
        child: versions.isEmpty
            ? const Text('No version history recorded.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: versions.length,
                itemBuilder: (context, index) {
                  final v = versions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('v${v.versionNumber}',
                          style: theme.textTheme.labelSmall),
                    ),
                    title: Text(v.title, style: theme.textTheme.bodyMedium),
                    subtitle: Text(
                      '${v.author} • ${v.createdAt.toLocal().toString().split('.')[0]}',
                      style: theme.textTheme.labelSmall,
                    ),
                    trailing: TextButton(
                      onPressed: () => onRestoreVersion(v),
                      child: const Text('Restore'),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
