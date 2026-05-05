import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const bool _showPushDebugSection = false;
  bool _loading = true;
  bool _sendingTestNotification = false;
  bool _syncingPushToken = false;
  String? _fcmToken;
  String? _pushDebugStatus;
  
  // Channel settings
  bool _pushEnabled = false;
  bool _emailEnabled = true;
  
  // Notification type settings
  bool _nearbyDealsEnabled = true;
  int _nearbyRadius = 5;
  bool _favoriteStoresEnabled = true;
  bool _expiringDealsEnabled = true;
  int _expiringHours = 24;
  bool _priceDropsEnabled = true;
  bool _flashSalesEnabled = true;
  bool _weeklyDigestEnabled = true;
  
  // Quiet hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);
  
  // Categories
  List<String> _selectedCategories = [];
  final List<String> _availableCategories = [
    'fashion',
    'electronics',
    'food',
    'travel',
    'health',
    'entertainment',
    'home',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadPushDebugState();
  }

  Future<void> _loadPushDebugState() async {
    final token = await PushNotificationService.getToken();
    if (!mounted) return;
    setState(() {
      _fcmToken = token;
      _pushDebugStatus = token == null || token.isEmpty
          ? 'No FCM token found on this device yet.'
          : 'FCM token is available on this device.';
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await ApiService().getNotificationPreferences();
      setState(() {
        // Load channel settings
        _pushEnabled = prefs['channels']?['push']?['enabled'] ?? false;
        _emailEnabled = prefs['channels']?['email']?['enabled'] ?? true;
        
        // Load notification type settings
        _nearbyDealsEnabled = prefs['preferences']?['nearbyDeals']?['enabled'] ?? true;
        _nearbyRadius = prefs['preferences']?['nearbyDeals']?['radius'] ?? 5;
        _favoriteStoresEnabled = prefs['preferences']?['favoriteStores']?['enabled'] ?? true;
        _expiringDealsEnabled = prefs['preferences']?['expiringDeals']?['enabled'] ?? true;
        _expiringHours = prefs['preferences']?['expiringDeals']?['hours'] ?? 24;
        _priceDropsEnabled = prefs['preferences']?['priceDrops']?['enabled'] ?? true;
        _flashSalesEnabled = prefs['preferences']?['flashSales']?['enabled'] ?? true;
        _weeklyDigestEnabled = prefs['preferences']?['weeklyDigest']?['enabled'] ?? true;
        
        // Load quiet hours
        _quietHoursEnabled = prefs['quietHours']?['enabled'] ?? false;
        final startParts = (prefs['quietHours']?['start'] ?? '22:00').split(':');
        final endParts = (prefs['quietHours']?['end'] ?? '08:00').split(':');
        _quietStart = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
        _quietEnd = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
        
        // Load categories
        _selectedCategories = List<String>.from(prefs['preferences']?['categories'] ?? []);
        
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preferences: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      final updatedPrefs = {
        'channels': {
          'push': {'enabled': _pushEnabled},
          'email': {'enabled': _emailEnabled},
        },
        'preferences': {
          'nearbyDeals': {'enabled': _nearbyDealsEnabled, 'radius': _nearbyRadius},
          'favoriteStores': {'enabled': _favoriteStoresEnabled},
          'expiringDeals': {'enabled': _expiringDealsEnabled, 'hours': _expiringHours},
          'priceDrops': {'enabled': _priceDropsEnabled},
          'flashSales': {'enabled': _flashSalesEnabled},
          'weeklyDigest': {'enabled': _weeklyDigestEnabled},
          'categories': _selectedCategories,
        },
        'quietHours': {
          'enabled': _quietHoursEnabled,
          'start': '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}',
          'end': '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}',
        },
      };

      await ApiService().updateNotificationPreferences(updatedPrefs);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e')),
        );
      }
    }
  }

  Future<void> _togglePushNotifications(bool value) async {
    if (value) {
      // Request permission and subscribe
      final token = await PushNotificationService.getToken();
      if (token != null) {
        await ApiService().subscribeToNotifications(token, 'push');
        if (!mounted) return;
        setState(() {
          _pushEnabled = true;
          _fcmToken = token;
          _pushDebugStatus = 'Push enabled and token synced to backend.';
        });
      }
    } else {
      // Unsubscribe
      await ApiService().unsubscribeFromNotifications('push');
      if (!mounted) return;
      setState(() {
        _pushEnabled = false;
        _pushDebugStatus = 'Push disabled for this account.';
      });
    }
  }

  Future<void> _syncPushTokenToBackend() async {
    if (_syncingPushToken) return;

    setState(() => _syncingPushToken = true);
    try {
      final token = await PushNotificationService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No FCM token found on this device.');
      }

      await PushNotificationService.syncTokenWithServer(token);

      if (!mounted) return;
      setState(() {
        _fcmToken = token;
        _pushDebugStatus = 'FCM token synced to backend successfully.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push token synced to backend')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pushDebugStatus = 'Push token sync failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync push token: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _syncingPushToken = false);
      }
    }
  }

  Future<void> _copyToken() async {
    final token = _fcmToken;
    if (token == null || token.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FCM token copied')),
    );
  }

  Future<void> _sendTestNotification() async {
    if (_sendingTestNotification) return;

    setState(() => _sendingTestNotification = true);
    try {
      final result = await ApiService().sendTestNotification();
      final summary = (result['summary'] as Map<String, dynamic>?) ?? const {};
      final push = (summary['push'] as Map<String, dynamic>?) ?? const {};
      final web = (summary['web'] as Map<String, dynamic>?) ?? const {};
      final email = (summary['email'] as Map<String, dynamic>?) ?? const {};

      final debugLines = [
        'Push: ${_formatChannelStatus(push)}',
        'Web: ${_formatChannelStatus(web)}',
        'Email: ${_formatChannelStatus(email)}',
      ].join('\n');

      if (mounted) {
        setState(() {
          _pushDebugStatus = debugLines;
        });

        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Notification Result'),
            content: SelectableText(debugLines),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send test: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingTestNotification = false);
      }
    }
  }

  String _formatChannelStatus(Map<String, dynamic> status) {
    final attempted = status['attempted'] == true;
    final success = status['success'] == true;
    final error = status['error'];

    if (!attempted) {
      return 'not attempted';
    }

    if (success) {
      return 'success';
    }

    if (error is String && error.isNotEmpty) {
      return 'failed ($error)';
    }

    return 'failed';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Channels Section
          _buildSectionHeader('Notification Channels'),
          _buildSwitchTile(
            'Push Notifications',
            'Receive notifications on this device',
            _pushEnabled,
            (value) => _togglePushNotifications(value),
            icon: Icons.notifications_active,
          ),
          _buildSwitchTile(
            'Email Notifications',
            'Receive notifications via email',
            _emailEnabled,
            (value) => setState(() => _emailEnabled = value),
            icon: Icons.email,
          ),
          
          const Divider(height: 32),
          
          // Notification Types Section
          _buildSectionHeader('Notification Types'),
          _buildSwitchTile(
            'Nearby Deals',
            'Get notified about deals near you',
            _nearbyDealsEnabled,
            (value) => setState(() => _nearbyDealsEnabled = value),
            icon: Icons.location_on,
          ),
          if (_nearbyDealsEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Radius: ${_nearbyRadius}km'),
                  Slider(
                    value: _nearbyRadius.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${_nearbyRadius}km',
                    onChanged: (value) => setState(() => _nearbyRadius = value.toInt()),
                  ),
                ],
              ),
            ),
          
          _buildSwitchTile(
            'Favorite Stores',
            'New deals from stores you follow',
            _favoriteStoresEnabled,
            (value) => setState(() => _favoriteStoresEnabled = value),
            icon: Icons.favorite,
          ),
          
          _buildSwitchTile(
            'Expiring Deals',
            'Reminders for deals about to expire',
            _expiringDealsEnabled,
            (value) => setState(() => _expiringDealsEnabled = value),
            icon: Icons.access_time,
          ),
          if (_expiringDealsEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notify $_expiringHours hours before expiry'),
                  Slider(
                    value: _expiringHours.toDouble(),
                    min: 6,
                    max: 72,
                    divisions: 11,
                    label: '${_expiringHours}h',
                    onChanged: (value) => setState(() => _expiringHours = value.toInt()),
                  ),
                ],
              ),
            ),
          
          _buildSwitchTile(
            'Price Drops',
            'Get notified when prices drop',
            _priceDropsEnabled,
            (value) => setState(() => _priceDropsEnabled = value),
            icon: Icons.trending_down,
          ),
          
          _buildSwitchTile(
            'Flash Sales',
            'Urgent alerts for limited-time offers',
            _flashSalesEnabled,
            (value) => setState(() => _flashSalesEnabled = value),
            icon: Icons.flash_on,
          ),
          
          _buildSwitchTile(
            'Weekly Digest',
            'Summary of top deals every week',
            _weeklyDigestEnabled,
            (value) => setState(() => _weeklyDigestEnabled = value),
            icon: Icons.email_outlined,
          ),
          
          if (_showPushDebugSection) ...[
            const Divider(height: 32),
            _buildSectionHeader('Push Debug'),
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pushDebugStatus ?? 'Checking push registration state...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _fcmToken == null || _fcmToken!.isEmpty
                          ? 'FCM token: not available'
                          : 'FCM token:\n$_fcmToken',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _loadPushDebugState,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Token'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _syncingPushToken ? null : _syncPushTokenToBackend,
                          icon: const Icon(Icons.cloud_upload),
                          label: Text(
                            _syncingPushToken ? 'Syncing...' : 'Sync Token to Backend',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: (_fcmToken == null || _fcmToken!.isEmpty) ? null : _copyToken,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Token'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
          ],
          
          // Categories Section
          _buildSectionHeader('Interested Categories'),
          Wrap(
            spacing: 8,
            children: _availableCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category[0].toUpperCase() + category.substring(1)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const Divider(height: 32),
          
          // Quiet Hours Section
          _buildSectionHeader('Quiet Hours'),
          _buildSwitchTile(
            'Enable Quiet Hours',
            'Pause notifications during specific times',
            _quietHoursEnabled,
            (value) => setState(() => _quietHoursEnabled = value),
            icon: Icons.bedtime,
          ),
          if (_quietHoursEnabled) ...[
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Start Time'),
              trailing: Text(_quietStart.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _quietStart,
                );
                if (time != null) {
                  setState(() => _quietStart = time);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: const Text('End Time'),
              trailing: Text(_quietEnd.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _quietEnd,
                );
                if (time != null) {
                  setState(() => _quietEnd = time);
                }
              },
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Test Notification Button
          ElevatedButton.icon(
            onPressed: _sendingTestNotification ? null : _sendTestNotification,
            icon: const Icon(Icons.send),
            label: Text(
              _sendingTestNotification
                  ? 'Sending Test Notification...'
                  : 'Send Test Notification',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    IconData? icon,
  }) {
    return SwitchListTile(
      secondary: icon != null ? Icon(icon, color: Colors.deepPurple) : null,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
