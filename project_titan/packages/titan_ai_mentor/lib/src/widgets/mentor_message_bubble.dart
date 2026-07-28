import 'package:flutter/material.dart';

import '../models/mentor_message.dart';
import 'mentor_action_card.dart';

/// Material 3 message bubble for displaying mentor and user chat messages.
class MentorMessageBubble extends StatelessWidget {
  final MentorMessage message;
  final ValueChanged<String>? onActionPressed;

  const MentorMessageBubble({
    super.key,
    required this.message,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.sender == MentorMessageSender.user;

    final bubbleColor = isUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final textColor =
        isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16.0,
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.smart_toy,
                  size: 18.0, color: colorScheme.onPrimary),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18.0),
                  topRight: const Radius.circular(18.0),
                  bottomLeft: Radius.circular(isUser ? 18.0 : 4.0),
                  bottomRight: Radius.circular(isUser ? 4.0 : 18.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                  if (message.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 10.0),
                    ...message.recommendations.map(
                      (rec) => MentorActionCard(
                        recommendation: rec,
                        onPressed: onActionPressed != null
                            ? () => onActionPressed!(rec.actionType)
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            CircleAvatar(
              radius: 16.0,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(Icons.person,
                  size: 18.0, color: colorScheme.onSecondaryContainer),
            ),
          ],
        ],
      ),
    );
  }
}
