import 'package:flutter/material.dart';
import '../services/push_notification_service.dart';

/// Explains deal alerts before the system permission popup, which can only be
/// shown a limited number of times. Call this only for signed-in people.
Future<void> offerPushNotifications(BuildContext context) async {
  if (!await PushNotificationService.shouldOfferPermission()) return;
  await PushNotificationService.markPermissionOffered();
  if (!context.mounted) return;
  String t(String en, String si, String ta) =>
      switch (Localizations.localeOf(context).languageCode) {
        'si' => si,
        'ta' => ta,
        _ => en
      };
  final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
            title: Text(t('Get deal alerts?', 'දීමනා දැනුම්දීම් ලබාගන්නද?',
                'சலுகை அறிவிப்புகள் வேண்டுமா?')),
            content: Text(t(
                "We'll tell you about nearby deals and offers ending soon. You can change this anytime in Settings.",
                'අසල දීමනා සහ ඉක්මනින් අවසන් වන දීමනා ගැන අපි ඔබට දන්වන්නෙමු. ඔබට ඕනෑම වේලාවක සැකසුම් තුළින් මෙය වෙනස් කළ හැක.',
                'அருகிலுள்ள சலுகைகள் மற்றும் விரைவில் முடியும் சலுகைகள் பற்றி உங்களுக்குத் தெரிவிப்போம். அமைப்புகளில் எப்போது வேண்டுமானாலும் இதை மாற்றலாம்.')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialog).pop(false),
                  child: Text(t('Not now', 'දැන් නොවේ', 'இப்போது வேண்டாம்'))),
              FilledButton(
                  onPressed: () => Navigator.of(dialog).pop(true),
                  child: Text(t('Turn on', 'සක්‍රිය කරන්න', 'இயக்கு'))),
            ],
          ));
  if (accepted != true) return;
  try {
    await PushNotificationService.requestPermissionAndGetToken();
  } catch (_) {
    // Settings still offers push if the first attempt fails.
  }
}
