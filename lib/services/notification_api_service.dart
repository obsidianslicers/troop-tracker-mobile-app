import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/push_notification.dart';
import 'push_notification_service.dart';

class NotificationApiService {
  static Map<String, String> get _headers => {
        'FCM-Token': PushNotificationService.currentToken ?? '',
        'Accept': 'application/json',
      };

  static Uri _uri(String path) =>
      Uri.parse('${AppConfig.trackerUrl.replaceAll(RegExp(r'/$'), '')}$path');

  static Future<List<PushNotification>> fetchAll() async {
    try {
      final response = await http.get(_uri('/api/push-notifications'), headers: _headers);
      if (response.statusCode != 200) {
        debugPrint(
          '[NotificationApi] fetchAll non-200: ${response.statusCode} '
          '(device likely not registered yet)',
        );
        return [];
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => PushNotification.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[NotificationApi] fetchAll error: $e');
      return [];
    }
  }

  static Future<void> markRead(String id) async {
    try {
      await http.post(_uri('/api/push-notifications/$id/read'), headers: _headers);
    } catch (e) {
      debugPrint('[NotificationApi] markRead error: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      await http.delete(_uri('/api/push-notifications'), headers: _headers);
    } catch (e) {
      debugPrint('[NotificationApi] clearAll error: $e');
    }
  }
}
