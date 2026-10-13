import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../widgets/app_empty_state.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final notifications = await _api.fetchNotifications();
    await PushNotificationService.syncAppIconBadgeWithServer();
    return notifications;
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = _loadNotifications();
    });
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _api.deleteNotification(id);
      await _refreshNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final id = notification['_id'] as String?;
    final alreadyRead = notification['read'] == true;

    if (id != null && id.isNotEmpty && !alreadyRead) {
      await _api.markNotificationAsRead(id).catchError((_) {});
      await PushNotificationService.syncAppIconBadgeWithServer();
    }

    await PushNotificationService.handleNotificationData(notification);
    await _refreshNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AppEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title:
                        AppLocalizations.of(context)!.loadNotificationsFailed,
                    message: AppLocalizations.of(context)!.checkConnectionRetry,
                    actionLabel: 'Retry',
                    onAction: _refreshNotifications);
              }
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: AppLocalizations.of(context)!.caughtUpTitle,
                    message: AppLocalizations.of(context)!.caughtUpMessage);
              }
              return RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final unread = notification['read'] != true;
                        return Material(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            child: ListTile(
                              onTap: () => _openNotification(notification),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(16, 10, 6, 10),
                              leading: CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  child: Icon(Icons.notifications_none_rounded,
                                      color: scheme.primary)),
                              title: Text(notification['title'] ?? 'Update',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: unread
                                          ? FontWeight.w700
                                          : FontWeight.w500)),
                              subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                      notification['body'] ??
                                          notification['type'] ??
                                          '',
                                      style: theme.textTheme.bodySmall)),
                              trailing: IconButton(
                                  tooltip: AppLocalizations.of(context)!
                                      .deleteNotificationLabel,
                                  icon:
                                      const Icon(Icons.close_rounded, size: 19),
                                  onPressed: () {
                                    final id = notification['_id'] as String?;
                                    if (id?.isNotEmpty ?? false) {
                                      _deleteNotification(id!);
                                    }
                                  }),
                            ));
                      }));
            }));
  }
}
