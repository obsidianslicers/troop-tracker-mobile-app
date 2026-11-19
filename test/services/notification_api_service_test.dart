import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tt_mobile_app/services/notification_api_service.dart';
import 'package:tt_mobile_app/services/push_notification_service.dart';

import '../support/test_env.dart';

void main() {
  late List<http.Request> requests;

  NotificationApiService subjectReturning(http.Response response, {String? token = 'tok'}) {
    return NotificationApiService(
      client: MockClient((request) async {
        requests.add(request);
        return response;
      }),
      token: () => token,
    );
  }

  setUp(() {
    loadTestEnv();
    requests = [];
    PushNotificationService.reset();
  });

  group('fetchAll', () {
    test('returns the notifications and sends the device token', () async {
      final subject = subjectReturning(
        http.Response(
          jsonEncode([
            {
              'id': '1',
              'title': 'Hello',
              'body': 'World',
              'url': '/events/1',
              'read_at': null,
              'created_at': '2026-11-01T10:00:00Z',
            },
          ]),
          200,
        ),
      );

      final result = await subject.fetchAll();

      expect(result.single.id, '1');
      expect(requests.single.method, 'GET');
      expect(requests.single.url.toString(), 'https://tracker.example.org/api/push-notifications');
      expect(requests.single.headers['FCM-Token'], 'tok');
      expect(requests.single.headers['Accept'], 'application/json');
    });

    test('returns nothing when the device is not registered', () async {
      final subject = subjectReturning(http.Response('Unauthorized', 401));

      expect(await subject.fetchAll(), isEmpty);
    });

    test('returns nothing when the response is not JSON', () async {
      final subject = subjectReturning(http.Response('<html>', 200));

      expect(await subject.fetchAll(), isEmpty);
    });

    test('sends an empty token before the device has one', () async {
      final subject = subjectReturning(http.Response('[]', 200), token: null);

      await subject.fetchAll();

      expect(requests.single.headers['FCM-Token'], '');
    });
  });

  test('markRead posts to the notification', () async {
    final subject = subjectReturning(http.Response('', 204));

    await subject.markRead('abc');

    expect(requests.single.method, 'POST');
    expect(
      requests.single.url.toString(),
      'https://tracker.example.org/api/push-notifications/abc/read',
    );
  });

  test('clearAll deletes the inbox', () async {
    final subject = subjectReturning(http.Response('', 204));

    await subject.clearAll();

    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.toString(), 'https://tracker.example.org/api/push-notifications');
  });

  test('network errors are swallowed', () async {
    final subject = NotificationApiService(
      client: MockClient((_) async => throw http.ClientException('offline')),
      token: () => 'tok',
    );

    expect(await subject.fetchAll(), isEmpty);
    await subject.markRead('abc');
    await subject.clearAll();
  });

  test('uses the FCM token from PushNotificationService by default', () async {
    PushNotificationService.currentToken = 'device-token';
    final subject = NotificationApiService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('[]', 200);
      }),
    );

    await subject.fetchAll();

    expect(requests.single.headers['FCM-Token'], 'device-token');
  });

  test('builds its own HTTP client by default', () {
    expect(NotificationApiService(), isA<NotificationApiService>());
  });
}
