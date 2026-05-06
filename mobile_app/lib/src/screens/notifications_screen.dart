import 'package:flutter/material.dart';
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
    final unreadIds = notifications
        .where((notification) => notification['read'] != true)
        .map((notification) => notification['_id'] as String?)
        .whereType<String>()
        .toList();

    if (unreadIds.isNotEmpty) {
      await Future.wait(
        unreadIds.map((id) => _api.markNotificationAsRead(id).catchError((_) {})),
      );
    }

    await PushNotificationService.syncAppIconBadgeWithServer();
    return await _api.fetchNotifications();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('No recent notifications'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.notifications, color: Colors.white, size: 20),
                ),
                title: Text(notification['title'] ?? 'No title'),
                subtitle: Text(notification['body'] ?? notification['type'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    final id = notification['_id'] as String?;
                    if (id != null && id.isNotEmpty) {
                      _deleteNotification(id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
