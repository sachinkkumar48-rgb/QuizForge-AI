import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manipulation_providers.dart';

/// Item in the organize pages working grid.
class _PageGridItem {
  final int originalPageNumber;
  int rotationDegrees = 0;
  bool isSelected = false;

  _PageGridItem({
    required this.originalPageNumber,
  });
}

/// Dialog presenting an interactive page grid for reorganizing, rotating, deleting, and inserting pages.
class OrganizePagesDialog extends ConsumerStatefulWidget {
  final String filePath;
  final int initialPageCount;

  const OrganizePagesDialog({
    super.key,
    required this.filePath,
    required this.initialPageCount,
  });

  @override
  ConsumerState<OrganizePagesDialog> createState() =>
      _OrganizePagesDialogState();
}

class _OrganizePagesDialogState extends ConsumerState<OrganizePagesDialog> {
  late List<_PageGridItem> _items;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _items = List.generate(
      widget.initialPageCount,
      (index) => _PageGridItem(originalPageNumber: index + 1),
    );
  }

  void _rotateSelected(int deg) {
    setState(() {
      for (final item in _items) {
        if (item.isSelected) {
          item.rotationDegrees =
              ((item.rotationDegrees + deg) % 360 + 360) % 360;
        }
      }
    });
  }

  void _rotateSingle(int index, int deg) {
    setState(() {
      final item = _items[index];
      item.rotationDegrees = ((item.rotationDegrees + deg) % 360 + 360) % 360;
    });
  }

  void _deleteSelected() {
    setState(() {
      if (_items.where((i) => !i.isSelected).isEmpty) {
        _errorMessage = 'Cannot delete all pages from the document.';
        return;
      }
      _items.removeWhere((i) => i.isSelected);
      _errorMessage = null;
    });
  }

  void _movePage(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex < 0 || newIndex >= _items.length) return;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  void _insertBlankPage(int index) {
    setState(() {
      final maxOrig = _items.fold<int>(0,
          (max, i) => i.originalPageNumber > max ? i.originalPageNumber : max);
      _items.insert(index, _PageGridItem(originalPageNumber: maxOrig + 1));
    });
  }

  Future<void> _applyChanges() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(pdfManipulationServiceProvider);

      // Check if reordering / rotations occurred
      final newOrder = _items.map((i) => i.originalPageNumber).toList();
      final rotations = <int, int>{};
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.rotationDegrees != 0) {
          rotations[i + 1] = item.rotationDegrees;
        }
      }

      var result = await service.reorderPages(
        sourcePath: widget.filePath,
        newOrder: newOrder,
      );

      if (rotations.isNotEmpty) {
        result = await service.rotatePages(
          sourcePath: result.primaryOutputPath,
          pageRotations: rotations,
          customOutputPath: result.primaryOutputPath,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Operation failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _items.where((i) => i.isSelected).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 720,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_stories, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Organize Pages',
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

            // Action Toolbar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.rotate_right, size: 18),
                  label: const Text('Rotate 90°'),
                  onPressed:
                      selectedCount == 0 ? null : () => _rotateSelected(90),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                      selectedCount > 0 ? 'Delete ($selectedCount)' : 'Delete'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                  onPressed: selectedCount == 0 ? null : _deleteSelected,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  label: const Text('Insert Blank'),
                  onPressed: () => _insertBlankPage(_items.length),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final allSelected = selectedCount == _items.length;
                      for (final i in _items) {
                        i.isSelected = !allSelected;
                      }
                    });
                  },
                  child: Text(selectedCount == _items.length
                      ? 'Deselect All'
                      : 'Select All'),
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

            // Page Grid
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No pages in document.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildPageCard(context, index, item, theme);
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
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Apply Changes'),
                  onPressed: _isProcessing ? null : _applyChanges,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard(
      BuildContext context, int index, _PageGridItem item, ThemeData theme) {
    return Card(
      elevation: item.isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: item.isSelected
              ? theme.colorScheme.primary
              : Colors.grey.shade300,
          width: item.isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            item.isSelected = !item.isSelected;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Page Header with Rotation badge and Checkbox
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: item.isSelected,
                      onChanged: (val) {
                        setState(() {
                          item.isSelected = val ?? false;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.rotationDegrees > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.rotationDegrees}°',
                        style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                ],
              ),
              // Simulated Page Content Box
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: (item.rotationDegrees * 3.1415926535) / 180,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description,
                              size: 32, color: Colors.grey.shade600),
                          const SizedBox(height: 4),
                          Text(
                            'Orig #${item.originalPageNumber}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Page Quick Action Buttons (Rotate / Move Left / Move Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: index > 0 ? () => _movePage(index, index - 1) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.arrow_left,
                          size: 16,
                          color: index > 0
                              ? theme.colorScheme.onSurface
                              : theme.disabledColor),
                    ),
                  ),
                  InkWell(
                    onTap: () => _rotateSingle(index, 90),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.rotate_right, size: 16),
                    ),
                  ),
                  InkWell(
                    onTap: index < _items.length - 1
                        ? () => _movePage(index, index + 1)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.arrow_right,
                          size: 16,
                          color: index < _items.length - 1
                              ? theme.colorScheme.onSurface
                              : theme.disabledColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
