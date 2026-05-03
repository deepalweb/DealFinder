import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = true;
  
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
        setState(() => _pushEnabled = true);
      }
    } else {
      // Unsubscribe
      await ApiService().unsubscribeFromNotifications('push');
      setState(() => _pushEnabled = false);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await ApiService().sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send test: $e')),
        );
      }
    }
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
          
          const Divider(height: 32),
          
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
            onPressed: _sendTestNotification,
            icon: const Icon(Icons.send),
            label: const Text('Send Test Notification'),
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
