import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/pdf_embedded_file.dart';
import '../providers/attachment_providers.dart';

/// Displays the embedded file attachments inspector and extractor bottom sheet.
Future<void> showAttachmentsPanel(
  BuildContext context, {
  required String filePath,
  required String documentTitle,
  String? targetExtractionDirectory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => AttachmentsPanel(
      filePath: filePath,
      documentTitle: documentTitle,
      targetExtractionDirectory: targetExtractionDirectory,
    ),
  );
}

/// Bottom sheet panel inspecting and allowing safe extraction of embedded files inside a PDF.
class AttachmentsPanel extends ConsumerStatefulWidget {
  final String filePath;
  final String documentTitle;
  final String? targetExtractionDirectory;

  const AttachmentsPanel({
    super.key,
    required this.filePath,
    required this.documentTitle,
    this.targetExtractionDirectory,
  });

  @override
  ConsumerState<AttachmentsPanel> createState() => _AttachmentsPanelState();
}

class _AttachmentsPanelState extends ConsumerState<AttachmentsPanel> {
  bool _isExtracting = false;

  Future<String> _resolveExtractDirectory() async {
    if (widget.targetExtractionDirectory != null) {
      return widget.targetExtractionDirectory!;
    }
    // Default extraction destination: adjacent to source PDF or temporary directory
    final parentDir = File(widget.filePath).parent.path;
    final extractDir = '$parentDir/extracted_attachments';
    await Directory(extractDir).create(recursive: true);
    return extractDir;
  }

  Future<void> _extractSingle(PdfEmbeddedFile attachment) async {
    setState(() => _isExtracting = true);
    try {
      final destDir = await _resolveExtractDirectory();
      final service = ref.read(pdfAttachmentServiceProvider);
      final result = await service.extractAttachment(
        sourceFilePath: widget.filePath,
        attachment: attachment,
        targetDirectoryPath: destDir,
      );

      if (!mounted) return;
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Extracted "${attachment.filename}" to: ${result.outputPath}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extract: ${result.errorMessage}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _extractAll(List<PdfEmbeddedFile> attachments) async {
    setState(() => _isExtracting = true);
    try {
      final destDir = await _resolveExtractDirectory();
      final service = ref.read(pdfAttachmentServiceProvider);
      final results = await service.extractAllAttachments(
        sourceFilePath: widget.filePath,
        targetDirectoryPath: destDir,
      );

      if (!mounted) return;
      final successCount = results.where((r) => r.isSuccess).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Extracted $successCount of ${attachments.length} attachments to: $destDir'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync =
        ref.watch(attachmentsForDocumentProvider(widget.filePath));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.attach_file,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Embedded Attachments',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          widget.documentTitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  attachmentsAsync.when(
                    data: (attachments) => attachments.isNotEmpty
                        ? TextButton.icon(
                            key: const Key('extract-all-attachments-button'),
                            onPressed: _isExtracting
                                ? null
                                : () => _extractAll(attachments),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Extract All'),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: attachmentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to inspect attachments: $err'),
                  ),
                ),
                data: (attachments) {
                  if (attachments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attachment,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No embedded attachments found',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This document does not contain embedded files or file attachment annotations.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final item = attachments[index];
                      return _AttachmentTile(
                        key: ValueKey('attachment-${item.id}'),
                        attachment: item,
                        isExtracting: _isExtracting,
                        onExtract: () => _extractSingle(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final PdfEmbeddedFile attachment;
  final bool isExtracting;
  final VoidCallback onExtract;

  const _AttachmentTile({
    super.key,
    required this.attachment,
    required this.isExtracting,
    required this.onExtract,
  });

  IconData _iconForExtension(String ext, String? mime) {
    if (mime != null && mime.startsWith('image/')) return Icons.image_outlined;
    if (ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'gif' ||
        ext == 'svg') {
      return Icons.image_outlined;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (ext == 'txt' ||
        ext == 'md' ||
        ext == 'csv' ||
        ext == 'json' ||
        ext == 'xml') {
      return Icons.description_outlined;
    }
    if (ext == 'xlsx' || ext == 'xls') {
      return Icons.table_chart_outlined;
    }
    if (ext == 'zip' || ext == 'gz' || ext == 'tar') {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final ext = attachment.fileExtension;
    final icon = _iconForExtension(ext, attachment.mimeType);

    final details = <String>[
      attachment.formattedSize,
      if (attachment.mimeType != null && attachment.mimeType!.isNotEmpty)
        attachment.mimeType!
      else
        attachment.sourceLocation.label,
      if (attachment.pageNumber != null) 'Page ${attachment.pageNumber}',
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child:
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(
        attachment.filename,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            details.join(' • '),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (attachment.description != null &&
              attachment.description!.isNotEmpty)
            Text(
              attachment.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ),
      trailing: FilledButton.tonalIcon(
        key: ValueKey('extract-btn-${attachment.id}'),
        onPressed: isExtracting ? null : onExtract,
        icon: const Icon(Icons.download, size: 16),
        label: const Text('Extract'),
      ),
    );
  }
}
