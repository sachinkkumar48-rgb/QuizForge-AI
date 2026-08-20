import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../providers/manipulation_providers.dart';

/// Dialog allowing users to select multiple PDFs, reorder them, and merge into a single PDF.
class MergePdfsDialog extends ConsumerStatefulWidget {
  final List<String> initialFiles;

  const MergePdfsDialog({
    super.key,
    this.initialFiles = const [],
  });

  @override
  ConsumerState<MergePdfsDialog> createState() => _MergePdfsDialogState();
}

class _MergePdfsDialogState extends ConsumerState<MergePdfsDialog> {
  final List<String> _filePaths = [];
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filePaths.addAll(widget.initialFiles);
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          for (final path in result.paths) {
            if (path != null && !_filePaths.contains(path)) {
              _filePaths.add(path);
            }
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick files: $e';
      });
    }
  }

  void _moveItem(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex < 0 || newIndex >= _filePaths.length) return;
      final path = _filePaths.removeAt(oldIndex);
      _filePaths.insert(newIndex, path);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _filePaths.removeAt(index);
    });
  }

  Future<void> _mergeFiles() async {
    if (_filePaths.length < 2) {
      setState(() {
        _errorMessage = 'Please add at least 2 PDF files to merge.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(pdfManipulationServiceProvider);
      final result = await service.mergePdfs(inputPaths: _filePaths);

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Merge failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.call_merge, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Merge PDF Documents',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      _isProcessing ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Toolbar
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add PDF Files'),
                  onPressed: _isProcessing ? null : _pickFiles,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_filePaths.length} file(s) selected',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
            const Divider(height: 24),

            // File List
            Expanded(
              child: _filePaths.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('No PDFs added yet.',
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          const Text(
                              'Click "Add PDF Files" to select documents to merge.'),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _filePaths.length,
                      onReorderItem: (oldIdx, newIdx) {
                        setState(() {
                          final item = _filePaths.removeAt(oldIdx);
                          _filePaths.insert(newIdx, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final filePath = _filePaths[index];
                        final name = p.basename(filePath);
                        return ListTile(
                          key: ValueKey(filePath),
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text('${index + 1}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(filePath,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                tooltip: 'Move Up',
                                onPressed: index > 0
                                    ? () => _moveItem(index, index - 1)
                                    : null,
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.arrow_downward, size: 18),
                                tooltip: 'Move Down',
                                onPressed: index < _filePaths.length - 1
                                    ? () => _moveItem(index, index + 1)
                                    : null,
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                tooltip: 'Remove',
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.merge_type, size: 18),
                  label: const Text('Merge Documents'),
                  onPressed: _isProcessing || _filePaths.length < 2
                      ? null
                      : _mergeFiles,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
