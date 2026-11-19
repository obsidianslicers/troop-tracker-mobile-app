import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/push_notification.dart';
import 'push_notification_service.dart';

/// The tracker's push notification inbox API. The device is identified by its
/// FCM token, which the web app registered for the signed-in trooper.
class NotificationApiService {
  NotificationApiService({http.Client? client, String? Function()? token})
      : _client = client ?? http.Client(),
        _token = token ?? (() => PushNotificationService.currentToken);

  final http.Client _client;
  final String? Function() _token;

  Map<String, String> get _headers => {'FCM-Token': _token() ?? '', 'Accept': 'application/json'};

  Uri _uri(String path) => Uri.parse(AppConfig.urlFor(path));

  /// The device's notifications, newest first. Empty when the request fails,
  /// for example because the device isn't registered yet.
  Future<List<PushNotification>> fetchAll() async {
    try {
      final response = await _client.get(_uri('/api/push-notifications'), headers: _headers);
      if (response.statusCode != 200) {
        debugPrint(
          '[NotificationApi] fetchAll non-200: ${response.statusCode} '
          '(device likely not registered yet)',
        );
        return [];
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => PushNotification.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[NotificationApi] fetchAll error: $e');
      return [];
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _client.post(_uri('/api/push-notifications/$id/read'), headers: _headers);
    } catch (e) {
      debugPrint('[NotificationApi] markRead error: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _client.delete(_uri('/api/push-notifications'), headers: _headers);
    } catch (e) {
      debugPrint('[NotificationApi] clearAll error: $e');
    }
  }
}
