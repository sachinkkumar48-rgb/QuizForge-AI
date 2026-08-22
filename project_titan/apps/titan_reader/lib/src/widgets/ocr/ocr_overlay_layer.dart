import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/normalized_page_rect.dart';
import '../../domain/entities/ocr/ocr_confidence.dart';
import '../../domain/entities/ocr/ocr_page_state.dart';
import '../../domain/entities/ocr/ocr_result.dart';
import '../../domain/entities/ocr/ocr_search_selection.dart';
import '../../domain/entities/ocr/ocr_text_region.dart';

/// Overlay widget rendering non-destructive OCR text bounding boxes, confidence badges,
/// visual text layers, search match highlights, text selection layers, and progress indicators
/// directly over a rendered PDF page.
class OcrOverlayLayer extends StatelessWidget {
  /// 1-based page number.
  final int pageNumber;

  /// Rendered page/viewport size in screen pixels.
  final Size viewportSize;

  /// Optional original PDF page size in points/user units.
  final Size? pageSize;

  /// OCR recognition outcome for this page.
  final OcrResult? result;

  /// Complete OCR lifecycle and processing state for this page.
  final OcrPageState? pageState;

  /// Active visual display mode.
  final OcrOverlayDisplayMode displayMode;

  /// Active search matches on this page.
  final List<OcrSearchMatch> searchMatches;

  /// Index of the currently active search match on this page.
  final int? activeSearchMatchIndex;

  /// Active text selection on this page.
  final OcrTextSelection? activeSelection;

  /// Callback when a recognized word token is tapped.
  final void Function(OcrWord word)? onWordTap;

  /// Callback when a recognized text line is tapped.
  final void Function(OcrLine line)? onLineTap;

  /// Callback when a recognized text block is tapped.
  final void Function(OcrBlock block)? onBlockTap;

  /// Callback when the active OCR text selection changes.
  final void Function(OcrTextSelection? selection)? onSelectionChanged;

  /// Callback when the user triggers the copy action on the selection.
  final void Function(OcrTextSelection selection)? onCopySelection;

  /// Callback to retry OCR processing on failure.
  final VoidCallback? onRetry;

  /// Callback to cancel active OCR processing.
  final VoidCallback? onCancel;

  /// Callback when the user toggles the overlay display mode.
  final void Function(OcrOverlayDisplayMode mode)? onDisplayModeChanged;

  /// Whether to render the floating OCR status and summary badge.
  final bool showControlBadge;

  /// Whether to render the floating selection toolbar/pill when a selection is active.
  final bool showSelectionToolbar;

  const OcrOverlayLayer({
    super.key,
    required this.pageNumber,
    required this.viewportSize,
    this.pageSize,
    this.result,
    this.pageState,
    this.displayMode = OcrOverlayDisplayMode.textAndBoxes,
    this.searchMatches = const [],
    this.activeSearchMatchIndex,
    this.activeSelection,
    this.onWordTap,
    this.onLineTap,
    this.onBlockTap,
    this.onSelectionChanged,
    this.onCopySelection,
    this.onRetry,
    this.onCancel,
    this.onDisplayModeChanged,
    this.showControlBadge = true,
    this.showSelectionToolbar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return const SizedBox.shrink();
    }

    final effectiveResult = result ?? pageState?.result;
    final effectiveMode = pageState?.displayMode ?? displayMode;
    final isProcessing = pageState?.isProcessing ?? false;
    final isError = pageState?.status == OcrProcessingStatus.error;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Text & Bounding Box Overlay Layer
        if (effectiveMode != OcrOverlayDisplayMode.hidden &&
            effectiveResult != null &&
            effectiveResult.isSuccess)
          ..._buildRegions(context, effectiveResult, effectiveMode),

        // 2. Search Match Highlights
        if (searchMatches.isNotEmpty)
          ..._buildSearchHighlights(context, viewportSize),

        // 3. Selection Highlights
        if (activeSelection != null)
          ..._buildSelectionHighlights(context, activeSelection!, viewportSize),

        // 4. In-Page Progress Indicator Card
        if (isProcessing) _buildProgressIndicator(context),

        // 5. In-Page Error & Retry Banner
        if (isError) _buildErrorCard(context),

        // 6. Floating OCR Summary & Mode Control Badge
        if (showControlBadge &&
            effectiveMode != OcrOverlayDisplayMode.hidden &&
            effectiveResult != null &&
            effectiveResult.isSuccess &&
            !isProcessing &&
            activeSelection == null)
          _buildSummaryBadge(context, effectiveResult, effectiveMode),

        // 7. Floating Selection Quick-Action Toolbar
        if (showSelectionToolbar && activeSelection != null && !isProcessing)
          _buildSelectionToolbar(context, activeSelection!),
      ],
    );
  }

  List<Widget> _buildRegions(
    BuildContext context,
    OcrResult res,
    OcrOverlayDisplayMode mode,
  ) {
    final widgets = <Widget>[];
    final scaleX = viewportSize.width;
    final scaleY = viewportSize.height;

    // Render word-level regions if available; fallback to lines or blocks
    if (res.words.isNotEmpty) {
      for (final word in res.words) {
        widgets.add(_buildWordWidget(context, word, scaleX, scaleY, mode));
      }
    } else if (res.lines.isNotEmpty) {
      for (final line in res.lines) {
        widgets.add(_buildLineWidget(context, line, scaleX, scaleY, mode));
      }
    } else {
      for (final block in res.blocks) {
        widgets.add(_buildBlockWidget(context, block, scaleX, scaleY, mode));
      }
    }

    return widgets;
  }

  Widget _buildWordWidget(
    BuildContext context,
    OcrWord word,
    double scaleX,
    double scaleY,
    OcrOverlayDisplayMode mode,
  ) {
    final b = word.boundingBox;
    final left = b.left * scaleX;
    final top = b.top * scaleY;
    final width = (b.right - b.left) * scaleX;
    final height = (b.bottom - b.top) * scaleY;

    final color = _confidenceColor(word.confidence);
    final tooltipText =
        '${word.text} (${(word.confidence.value * 100).toStringAsFixed(1)}% conf)';

    void handleWordTap() {
      onWordTap?.call(word);
      if (onSelectionChanged != null) {
        final selection = OcrTextSelection(
          documentId: pageState?.documentId ?? '',
          pageNumber: pageNumber,
          selectedText: word.text,
          startOffset: 0,
          endOffset: word.text.length,
          selectedTokenIndices: [word.wordIndex],
          boundingBoxes: [word.boundingBox],
        );
        onSelectionChanged?.call(selection);
      }
    }

    if (mode == OcrOverlayDisplayMode.invisibleSelectable) {
      return Positioned(
        key: Key('ocr-word-${word.wordIndex}-${word.text}'),
        left: left,
        top: top,
        width: width.clamp(8.0, double.infinity),
        height: height.clamp(8.0, double.infinity),
        child: Tooltip(
          message: tooltipText,
          child: InkWell(
            onTap: handleWordTap,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }

    final showText = mode == OcrOverlayDisplayMode.textAndBoxes;

    return Positioned(
      key: Key('ocr-word-${word.wordIndex}-${word.text}'),
      left: left,
      top: top,
      width: width.clamp(8.0, double.infinity),
      height: height.clamp(8.0, double.infinity),
      child: Tooltip(
        message: tooltipText,
        child: InkWell(
          onTap: handleWordTap,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color, width: 1.2),
              borderRadius: BorderRadius.circular(2.0),
            ),
            child: showText
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text(
                        word.text,
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.95),
                          backgroundColor: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLineWidget(
    BuildContext context,
    OcrLine line,
    double scaleX,
    double scaleY,
    OcrOverlayDisplayMode mode,
  ) {
    final b = line.boundingBox;
    final left = b.left * scaleX;
    final top = b.top * scaleY;
    final width = (b.right - b.left) * scaleX;
    final height = (b.bottom - b.top) * scaleY;

    final color = _confidenceColor(line.confidence);

    return Positioned(
      key: Key('ocr-line-${line.lineIndex}'),
      left: left,
      top: top,
      width: width.clamp(12.0, double.infinity),
      height: height.clamp(12.0, double.infinity),
      child: Tooltip(
        message:
            '${line.text} (${(line.confidence.value * 100).toStringAsFixed(1)}% conf)',
        child: InkWell(
          onTap: () => onLineTap?.call(line),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color, width: 1.2),
              borderRadius: BorderRadius.circular(2.0),
            ),
            child: mode == OcrOverlayDisplayMode.textAndBoxes
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      line.text,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w600,
                        color: color,
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBlockWidget(
    BuildContext context,
    OcrBlock block,
    double scaleX,
    double scaleY,
    OcrOverlayDisplayMode mode,
  ) {
    final b = block.boundingBox;
    final left = b.left * scaleX;
    final top = b.top * scaleY;
    final width = (b.right - b.left) * scaleX;
    final height = (b.bottom - b.top) * scaleY;

    final color = _confidenceColor(block.confidence);

    return Positioned(
      key: Key('ocr-block-${block.blockIndex}'),
      left: left,
      top: top,
      width: width.clamp(16.0, double.infinity),
      height: height.clamp(16.0, double.infinity),
      child: Tooltip(
        message: 'Block ${block.blockIndex}: ${block.text}',
        child: InkWell(
          onTap: () => onBlockTap?.call(block),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSearchHighlights(
      BuildContext context, Size viewportDimensions) {
    final widgets = <Widget>[];
    final scaleX = viewportDimensions.width;
    final scaleY = viewportDimensions.height;

    for (final match in searchMatches) {
      final isActive = match.index == activeSearchMatchIndex;
      final borderCol = isActive ? Colors.deepOrange : Colors.amber.shade800;
      final fillCol = isActive
          ? Colors.deepOrangeAccent.withValues(alpha: 0.55)
          : Colors.amber.withValues(alpha: 0.40);

      for (var boxIdx = 0; boxIdx < match.boundingBoxes.length; boxIdx++) {
        final b = match.boundingBoxes[boxIdx];
        final left = b.left * scaleX;
        final top = b.top * scaleY;
        final width = (b.right - b.left) * scaleX;
        final height = (b.bottom - b.top) * scaleY;

        widgets.add(Positioned(
          key: Key('ocr-search-match-${match.index}-$boxIdx'),
          left: left,
          top: top,
          width: width.clamp(4.0, double.infinity),
          height: height.clamp(4.0, double.infinity),
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: fillCol,
                border: Border.all(
                  color: borderCol,
                  width: isActive ? 2.0 : 1.2,
                ),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
        ));
      }
    }

    return widgets;
  }

  List<Widget> _buildSelectionHighlights(BuildContext context,
      OcrTextSelection selection, Size viewportDimensions) {
    final widgets = <Widget>[];
    final scaleX = viewportDimensions.width;
    final scaleY = viewportDimensions.height;

    for (var i = 0; i < selection.boundingBoxes.length; i++) {
      final b = selection.boundingBoxes[i];
      final left = b.left * scaleX;
      final top = b.top * scaleY;
      final width = (b.right - b.left) * scaleX;
      final height = (b.bottom - b.top) * scaleY;

      widgets.add(Positioned(
        key: Key('ocr-selection-box-$i'),
        left: left,
        top: top,
        width: width.clamp(4.0, double.infinity),
        height: height.clamp(4.0, double.infinity),
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.30),
              border: Border.all(color: Colors.blueAccent, width: 1.5),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
        ),
      ));
    }

    return widgets;
  }

  Widget _buildSelectionToolbar(
      BuildContext context, OcrTextSelection selection) {
    final theme = Theme.of(context);
    final snippet =
        selection.selectedText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final charCount = selection.selectedText.length;

    // Calculate approximate position above the selection
    final firstBox = selection.boundingBoxes.isNotEmpty
        ? selection.boundingBoxes.first
        : const NormalizedPageRect(
            left: 0.1, top: 0.1, right: 0.2, bottom: 0.15);
    final topPx = (firstBox.top * viewportSize.height - 48.0)
        .clamp(8.0, viewportSize.height - 50.0);
    final leftPx = (firstBox.left * viewportSize.width)
        .clamp(8.0, (viewportSize.width - 240.0).clamp(8.0, double.infinity));

    return Positioned(
      top: topPx,
      left: leftPx,
      child: Material(
        key: const Key('ocr-selection-toolbar'),
        elevation: 6,
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (snippet.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$charCount ch',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const Key('ocr-copy-selection-button'),
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy OCR text',
                onPressed: () async {
                  if (onCopySelection != null) {
                    onCopySelection!(selection);
                  } else {
                    await Clipboard.setData(
                        ClipboardData(text: selection.selectedText));
                  }
                },
              ),
              IconButton(
                key: const Key('ocr-clear-selection-button'),
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Clear selection',
                onPressed: () => onSelectionChanged?.call(null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final progress = pageState?.progress ?? 0.0;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        key: const Key('ocr-progress-card'),
        elevation: 4,
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  key: Key('ocr-progress-spinner'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Recognizing page $pageNumber text…',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress > 0.0 ? progress : null,
                      minHeight: 3,
                    ),
                  ],
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('ocr-cancel-button'),
                  tooltip: 'Cancel OCR',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onCancel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final errorMsg = pageState?.errorMessage ?? 'OCR recognition failed.';

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        key: const Key('ocr-error-card'),
        elevation: 4,
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  key: const Key('ocr-retry-button'),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(
    BuildContext context,
    OcrResult res,
    OcrOverlayDisplayMode mode,
  ) {
    final wordCount = res.words.length;
    final avgConf = (res.averageConfidence.value * 100).toStringAsFixed(0);
    final confColor = _confidenceColor(res.averageConfidence);

    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16.0),
        color: Colors.black87.withValues(alpha: 0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner, size: 14, color: confColor),
              const SizedBox(width: 6),
              Text(
                'OCR: $wordCount words ($avgConf%)',
                key: const Key('ocr-summary-text'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onDisplayModeChanged != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  key: const Key('ocr-mode-toggle-button'),
                  onTap: () {
                    final nextMode = switch (mode) {
                      OcrOverlayDisplayMode.textAndBoxes =>
                        OcrOverlayDisplayMode.boundingBoxesOnly,
                      OcrOverlayDisplayMode.boundingBoxesOnly =>
                        OcrOverlayDisplayMode.invisibleSelectable,
                      OcrOverlayDisplayMode.invisibleSelectable =>
                        OcrOverlayDisplayMode.hidden,
                      OcrOverlayDisplayMode.hidden =>
                        OcrOverlayDisplayMode.textAndBoxes,
                    };
                    onDisplayModeChanged?.call(nextMode);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      switch (mode) {
                        OcrOverlayDisplayMode.textAndBoxes =>
                          Icons.view_headline,
                        OcrOverlayDisplayMode.boundingBoxesOnly =>
                          Icons.crop_square,
                        OcrOverlayDisplayMode.invisibleSelectable =>
                          Icons.touch_app,
                        OcrOverlayDisplayMode.hidden => Icons.visibility_off,
                      },
                      size: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _confidenceColor(OcrConfidence confidence) {
    switch (confidence.level) {
      case OcrConfidenceLevel.high:
        return const Color(0xFF16A34A); // Green
      case OcrConfidenceLevel.medium:
        return const Color(0xFFD97706); // Amber
      case OcrConfidenceLevel.low:
        return const Color(0xFFDC2626); // Red
    }
  }
}
