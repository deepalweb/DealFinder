import 'package:deal_finder_mobile/src/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('offers once, then never again', () async {
    Future<bool> notAllowed() async => false;
    expect(
        await PushNotificationService.shouldOfferPermission(
            hasPermission: notAllowed),
        isTrue);
    await PushNotificationService.markPermissionOffered();
    expect(
        await PushNotificationService.shouldOfferPermission(
            hasPermission: notAllowed),
        isFalse);
  });

  test('does not offer when push is already allowed', () async {
    expect(
        await PushNotificationService.shouldOfferPermission(
            hasPermission: () async => true),
        isFalse);
  });

  test('a notification failure never blocks the app', () async {
    expect(
        await PushNotificationService.shouldOfferPermission(
            hasPermission: () async => throw StateError('No Firebase')),
        isFalse);
  });
}
