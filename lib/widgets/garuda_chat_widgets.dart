import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizforge_upsc/controllers/garuda_chat_viewmodel.dart';

/// PDF Knowledge Grounding Banner Widget
class PdfGroundingBanner extends StatelessWidget {
  final String documentName;

  const PdfGroundingBanner({super.key, required this.documentName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'PDF Grounding Banner: Answering from uploaded document $documentName',
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colorScheme.secondaryContainer,
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 20, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Answering from uploaded document: $documentName',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing Indicator Animated Widget
class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key});

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: 'GARUDA AI is typing',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          );
        }),
      ),
    );
  }
}

/// Reusable Markdown Text Renderer Supporting Headers, Bold, Italic, Lists, Code Blocks, Tables, Inline Code, Links, Blockquotes
class RichMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const RichMarkdownText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = text.split('\n');

    final List<Widget> widgets = [];
    bool inCodeBlock = false;
    final List<String> codeLines = [];
    final List<List<String>> tableRows = [];

    void flushTable() {
      if (tableRows.isNotEmpty) {
        widgets.add(_buildTable(context, List.from(tableRows)));
        tableRows.clear();
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('```')) {
        flushTable();
        if (inCodeBlock) {
          widgets.add(_buildCodeBlock(context, codeLines.join('\n')));
          codeLines.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }

      // Check for Markdown Table Row
      final trimmed = line.trim();
      if (trimmed.startsWith('|') && trimmed.endsWith('|') && trimmed.length > 2) {
        if (trimmed.replaceAll(RegExp(r'[\s|:-]'), '').isEmpty) {
          // Table delimiter row (e.g. |---|---|), skip adding to rows
          continue;
        }
        final cells = trimmed
            .substring(1, trimmed.length - 1)
            .split('|')
            .map((c) => c.trim())
            .toList();
        tableRows.add(cells);
        continue;
      } else {
        flushTable();
      }

      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.substring(2),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.substring(3),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(
            line.substring(4),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (line.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: _buildRichText(context, line.substring(2), style?.copyWith(fontStyle: FontStyle.italic)),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: _buildRichText(context, line.substring(2), style)),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^(\d+\.)\s').firstMatch(line)!;
        final numberPrefix = match.group(1)!;
        final content = line.substring(match.end);
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$numberPrefix ', style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: _buildRichText(context, content, style)),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(_buildRichText(context, line, style));
      }
    }

    flushTable();

    if (inCodeBlock && codeLines.isNotEmpty) {
      widgets.add(_buildCodeBlock(context, codeLines.join('\n')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(BuildContext context, String text, TextStyle? baseStyle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spans = <TextSpan>[];

    // Regex for bold (** or __), italic (* or _), inline code (`...`), and markdown links [text](url)
    final pattern = RegExp(
      r'(\*\*(.*?)\*\*|__(.*?)__|`([^`]+)`|\[(.*?)\]\((.*?)\)|\*(.*?)\*|_(.*?)_)',
    );

    int start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: baseStyle));
      }

      final fullMatch = match.group(0)!;
      if (fullMatch.startsWith('**') || fullMatch.startsWith('__')) {
        final content = match.group(2) ?? match.group(3) ?? '';
        spans.add(TextSpan(
          text: content,
          style: (baseStyle ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (fullMatch.startsWith('`')) {
        final content = match.group(4) ?? '';
        spans.add(TextSpan(
          text: content,
          style: (baseStyle ?? const TextStyle()).copyWith(
            fontFamily: 'monospace',
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ));
      } else if (fullMatch.startsWith('[')) {
        final linkText = match.group(5) ?? '';
        spans.add(TextSpan(
          text: linkText,
          style: (baseStyle ?? const TextStyle()).copyWith(
            color: colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ));
      } else if (fullMatch.startsWith('*') || fullMatch.startsWith('_')) {
        final content = match.group(7) ?? match.group(8) ?? '';
        spans.add(TextSpan(
          text: content,
          style: (baseStyle ?? const TextStyle()).copyWith(fontStyle: FontStyle.italic),
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return SelectableText.rich(
      TextSpan(children: spans, style: baseStyle ?? theme.textTheme.bodyMedium),
    );
  }

  Widget _buildTable(BuildContext context, List<List<String>> rows) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (rows.isEmpty) return const SizedBox.shrink();

    final isHeaderPresent = rows.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Table(
        border: TableBorder.all(
          color: colorScheme.outlineVariant,
          width: 1,
          borderRadius: BorderRadius.circular(4),
        ),
        children: rows.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;
          final isHeader = isHeaderPresent && rowIndex == 0;

          return TableRow(
            decoration: BoxDecoration(
              color: isHeader ? colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
            ),
            children: row.map((cell) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildRichText(
                  context,
                  cell,
                  isHeader
                      ? theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        )
                      : theme.textTheme.bodySmall,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'CODE BLOCK',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Copy code snippet',
                  child: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'Copy Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat Message Tile supporting User, Assistant, System, Error, and Loading Messages
class ChatMessageTile extends StatelessWidget {
  final ChatMessageDto message;
  final bool developerMode;
  final VoidCallback? onRetry;

  const ChatMessageTile({
    super.key,
    required this.message,
    this.developerMode = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (message.type == ChatMessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (message.type == ChatMessageType.loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.auto_awesome_rounded, size: 18, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.content.isEmpty ? 'GARUDA is processing...' : message.content,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (message.type == ChatMessageType.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.content,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
              if (onRetry != null)
                Semantics(
                  button: true,
                  label: 'Retry failed request',
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded, color: colorScheme.onErrorContainer),
                    onPressed: onRetry,
                    tooltip: 'Retry Message',
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final isUser = message.type == ChatMessageType.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Semantics(
        label: isUser ? 'User message: ${message.content}' : 'GARUDA response: ${message.content}',
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.auto_awesome_rounded, size: 18, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser && message.groundedPdfName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, size: 14, color: colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Grounded in PDF',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    RichMarkdownText(
                      text: message.content,
                      style: TextStyle(
                        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                    if (message.isStreaming && !isUser) ...[
                      const SizedBox(height: 6),
                      const ChatTypingIndicator(),
                    ],
                    if (developerMode && message.requestId != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ReqID: ${message.requestId}',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white70),
                        ),
                      ),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Semantics(
                          button: true,
                          label: 'Copy message to clipboard',
                          child: IconButton(
                            icon: Icon(Icons.copy_rounded, size: 14, color: isUser ? colorScheme.onPrimary : colorScheme.outline),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: message.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Message copied to clipboard')),
                              );
                            },
                            tooltip: 'Copy Message',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.person_rounded, size: 18, color: colorScheme.onSecondaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating Scroll-To-Bottom Button Widget
class ChatScrollToBottomButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ChatScrollToBottomButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Scroll to bottom of chat history',
      child: FloatingActionButton.small(
        onPressed: onPressed,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        tooltip: 'Scroll to bottom',
        child: const Icon(Icons.arrow_downward_rounded),
      ),
    );
  }
}

/// Multi-line Chat Input Bar Widget
class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback? onStop;
  final bool isGenerating;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onStop,
    required this.isGenerating,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isGenerating) {
      widget.onSend(text);
      _controller.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textLength = _controller.text.length;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _handleSend();
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !widget.isGenerating,
                      maxLines: 5,
                      minLines: 1,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: widget.isGenerating
                            ? 'GARUDA is thinking...'
                            : 'Ask GARUDA AI a question (Shift+Enter for newline)...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.isGenerating)
                  Semantics(
                    button: true,
                    label: 'Stop AI generation',
                    child: IconButton.filled(
                      onPressed: widget.onStop,
                      icon: const Icon(Icons.stop_rounded),
                      style: IconButton.styleFrom(backgroundColor: colorScheme.error),
                      tooltip: 'Stop Generation',
                    ),
                  )
                else
                  Semantics(
                    button: true,
                    label: 'Send message to GARUDA AI',
                    child: IconButton.filled(
                      onPressed: _controller.text.trim().isEmpty ? null : _handleSend,
                      icon: const Icon(Icons.send_rounded),
                      tooltip: 'Send Message',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shift+Enter for newline • Enter to send',
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  '$textLength / 1000',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textLength > 1000 ? colorScheme.error : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

