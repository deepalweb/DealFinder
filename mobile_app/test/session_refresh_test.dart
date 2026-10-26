import 'dart:convert';

import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response json(int status, Object body) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {'userToken': 'expired-access', 'refreshToken': 'refresh-1'}));

  Future<(Map<String, dynamic>?, List<String>)> run(
      http.Response Function(http.Request) backend) async {
    final calls = <String>[];
    Map<String, dynamic>? result;
    await http.runWithClient(() async {
      try {
        result = await ApiService().getNotificationPreferences();
      } catch (_) {}
    }, () => MockClient((request) async {
          calls.add(
              '${request.url.path} ${request.headers['Authorization'] ?? ''}');
          return backend(request);
        }));
    return (result, calls);
  }

  test('an expired access token (403) is refreshed and the request retried',
      () async {
    final (result, calls) = await run((request) {
      if (request.url.path.endsWith('users/refresh-token')) {
        expect(jsonDecode(request.body)['refreshToken'], 'refresh-1');
        return json(200, {'token': 'fresh-access', 'refreshToken': 'refresh-2'});
      }
      return request.headers['Authorization'] == 'Bearer fresh-access'
          ? json(200, {'channels': {}})
          : json(403, {'message': 'Invalid or expired token'});
    });
    expect(result, isNotNull);
    expect(calls.last, endsWith('Bearer fresh-access'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('userToken'), 'fresh-access');
    expect(prefs.getString('refreshToken'), 'refresh-2');
  });

  test('a revoked session stays revoked: no Firebase re-authentication',
      () async {
    final (result, calls) = await run((request) =>
        request.url.path.endsWith('users/refresh-token')
            ? json(401, {'message': 'Invalid refresh token'})
            : json(403, {'message': 'Invalid or expired token'}));
    expect(result, isNull);
    expect(calls.where((c) => c.contains('firebase-auth')), isEmpty);
    expect(calls.where((c) => c.contains('refresh-token')), hasLength(1));
  });

  test('a real permission error (403 Forbidden) does not trigger a refresh',
      () async {
    final (_, calls) =
        await run((_) => json(403, {'message': 'Forbidden: not yours'}));
    expect(calls.where((c) => c.contains('refresh-token')), isEmpty);
  });
}
