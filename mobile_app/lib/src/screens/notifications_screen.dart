import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;
  final String token;
  const NotificationsScreen({Key? key, required this.userId, required this.token}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService().fetchNotifications(widget.userId, widget.token);
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await ApiService().getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = prefs['channels']?['push']?['enabled'] ?? false;
      });
    } catch (_) {}
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      if (value) {
        final token = await PushNotificationService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('Push token is not available on this device yet.');
        }
        await ApiService().subscribeToNotifications(token, 'push');
      } else {
        await ApiService().unsubscribeFromNotifications('push');
      }

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Notifications enabled' : 'Notifications disabled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification setting: $e')),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = ApiService().fetchNotifications(widget.userId, widget.token);
    });
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await ApiService().deleteNotification(id);
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
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Deal Notifications'),
            subtitle: const Text('Get notified about new deals and offers'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
          ),
        ],
      ),
    );
  }
}
