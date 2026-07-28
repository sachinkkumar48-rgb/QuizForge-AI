import 'package:flutter/material.dart';

import '../models/mentor_message.dart';
import 'mentor_input_bar.dart';
import 'mentor_message_bubble.dart';
import 'mentor_typing_indicator.dart';
import 'offline_indicator_banner.dart';
import 'provider_status_badge.dart';

/// Production Material 3 full chat view combining message history stream,
/// streaming indicator, retry button, offline banner, and provider status badge.
class MentorChatView extends StatefulWidget {
  final List<MentorMessage> messages;
  final ValueChanged<String> onSend;
  final bool isThinking;
  final bool isOffline;
  final int queuedRequestCount;
  final String providerName;
  final int? latencyMs;
  final VoidCallback? onRetry;
  final VoidCallback? onSyncOfflineQueue;
  final ValueChanged<String>? onActionPressed;

  const MentorChatView({
    super.key,
    required this.messages,
    required this.onSend,
    this.isThinking = false,
    this.isOffline = false,
    this.queuedRequestCount = 0,
    this.providerName = 'Gemini',
    this.latencyMs,
    this.onRetry,
    this.onSyncOfflineQueue,
    this.onActionPressed,
  });

  @override
  State<MentorChatView> createState() => _MentorChatViewState();
}

class _MentorChatViewState extends State<MentorChatView> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        OfflineIndicatorBanner(
          isOffline: widget.isOffline,
          pendingQueueCount: widget.queuedRequestCount,
          onRetrySync: widget.onSyncOfflineQueue,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ProviderStatusBadge(
                providerName: widget.providerName,
                isOnline: !widget.isOffline,
                latencyMs: widget.latencyMs,
              ),
              if (widget.onRetry != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Retry Last Prompt',
                  onPressed: widget.onRetry,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined,
                          size: 56.0, color: theme.colorScheme.primary),
                      const SizedBox(height: 12.0),
                      Text(
                        'TITAN AI Mentor 2.0',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Your production-grade UPSC AI platform.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    return MentorMessageBubble(
                      message: msg,
                      onActionPressed: widget.onActionPressed,
                    );
                  },
                ),
        ),
        MentorTypingIndicator(isThinking: widget.isThinking),
        MentorInputBar(
          controller: _inputController,
          onSend: widget.onSend,
          isSending: widget.isThinking,
        ),
      ],
    );
  }
}
