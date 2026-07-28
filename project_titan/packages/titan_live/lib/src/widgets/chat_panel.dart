import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Real-time live chat panel widget.
class ChatPanel extends StatelessWidget {
  final List<ChatMessage> messages;
  final TextEditingController textController;
  final VoidCallback onSendPressed;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.textController,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        msg.senderName.isNotEmpty ? msg.senderName[0] : 'U',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${msg.senderName} • ${msg.senderRole.name}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              msg.message,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'Ask a question or comment...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: onSendPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
