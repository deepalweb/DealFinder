import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  bool _nearbyDealsEnabled = true;
  bool _favoriteStoresEnabled = true;
  bool _newDealsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nearbyDealsEnabled = prefs.getBool('notify_nearby_deals') ?? true;
      _favoriteStoresEnabled = prefs.getBool('notify_favorite_stores') ?? true;
      _newDealsEnabled = prefs.getBool('notify_new_deals') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Push Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Nearby Deals'),
              subtitle: const Text('Get notified when deals are available near you'),
              value: _nearbyDealsEnabled,
              onChanged: (value) {
                setState(() => _nearbyDealsEnabled = value);
                _saveSetting('notify_nearby_deals', value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Favorite Stores'),
              subtitle: const Text('New deals from stores you follow'),
              value: _favoriteStoresEnabled,
              onChanged: (value) {
                setState(() => _favoriteStoresEnabled = value);
                _saveSetting('notify_favorite_stores', value);
              },
            ),
            
            SwitchListTile(
              title: const Text('All New Deals'),
              subtitle: const Text('Get notified about all new deals'),
              value: _newDealsEnabled,
              onChanged: (value) {
                setState(() => _newDealsEnabled = value);
                _saveSetting('notify_new_deals', value);
              },
            ),
          ],
        ),
      ),
    );
  }
}