import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications right now.'))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isRead
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      item.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: item.isRead
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight:
                          item.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(item.body),
                  onTap: () {
                    ref.read(notificationProvider.notifier).markAsRead(item.id);
                  },
                );
              },
            ),
    );
  }
}
