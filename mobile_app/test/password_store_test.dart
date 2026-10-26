import 'dart:convert';

import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response json(int status, Object body) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

const session = {
  '_id': 'user-1',
  'name': 'Alex',
  'email': 'alex@example.test',
  'role': 'user',
  'token': 'access',
  'refreshToken': 'refresh'
};

Future<List<http.Request>> withBackend(
    http.Response Function(http.Request) backend, Future<void> Function() body) async {
  final calls = <http.Request>[];
  await http.runWithClient(body, () => MockClient((request) async {
        calls.add(request);
        return backend(request);
      }));
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('email sign-in uses the backend password and saves the session', () async {
    final calls = await withBackend(
        (_) => json(200, session),
        () => AuthService.loginWithEmail('alex@example.test', 'password-1'));
    expect(calls.first.url.path, endsWith('users/login'));
    expect((await SharedPreferences.getInstance()).getString('refreshToken'),
        'refresh');
  });

  test('a wrong password reports invalid credentials, not a raw error', () async {
    Object? error;
    await withBackend((_) => json(401, {'message': 'Invalid email or password'}),
        () async {
      try {
        await AuthService.loginWithEmail('alex@example.test', 'wrong');
      } catch (e) {
        error = e;
      }
    });
    expect(error, isA<InvalidCredentialsException>());
    expect(error.toString(), 'Invalid email or password.');
  });

  test('registration and password reset go to the backend', () async {
    final calls = await withBackend(
        (request) => request.url.path.endsWith('users/register')
            ? json(201, session)
            : json(200, {'message': 'sent'}), () async {
      await AuthService.registerWithEmail(
          name: 'Alex',
          email: 'alex@example.test',
          password: 'password-1',
          role: 'user');
      await AuthService.sendPasswordReset('alex@example.test');
    });
    expect(calls.map((c) => c.url.path.split('/').last).toList(),
        containsAllInOrder(['register', 'reset-password']));
    expect(jsonDecode(calls.first.body)['password'], 'password-1');
  });
}
