import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/config/app_config.dart';

import '../support/test_env.dart';

void main() {
  group('trackerUrl', () {
    test('comes from TRACKER_URL', () {
      loadTestEnv(trackerUrl: 'https://test.example.org/');

      expect(AppConfig.trackerUrl, 'https://test.example.org/');
    });

    test('falls back to the Florida Garrison tracker', () {
      dotenv.testLoad(fileInput: '');

      expect(AppConfig.trackerUrl, 'https://tracker.fl501st.com/');
    });
  });

  group('trackerDomain', () {
    test('is the registrable domain of the tracker host', () {
      loadTestEnv(trackerUrl: 'https://test.tracker.example.org/');

      expect(AppConfig.trackerDomain, 'example.org');
    });

    test('keeps localhost and IP addresses whole', () {
      loadTestEnv(trackerUrl: 'http://localhost:8000/');
      expect(AppConfig.trackerDomain, 'localhost');

      loadTestEnv(trackerUrl: 'http://192.168.1.20:8000/');
      expect(AppConfig.trackerDomain, '192.168.1.20');
    });

    test('keeps a single-label host whole', () {
      loadTestEnv(trackerUrl: 'http://tracker/');

      expect(AppConfig.trackerDomain, 'tracker');
    });
  });

  group('internalDomains', () {
    test('is the tracker domain plus the trimmed, lowercased INTERNAL_DOMAINS', () {
      loadTestEnv(internalDomains: ' Forum.Example.net ,, example.com ');

      expect(AppConfig.internalDomains, {'example.org', 'forum.example.net', 'example.com'});
    });

    test('is only the tracker domain when INTERNAL_DOMAINS is missing', () {
      dotenv.testLoad(fileInput: 'TRACKER_URL=https://tracker.example.org/');

      expect(AppConfig.extraInternalDomains, isEmpty);
      expect(AppConfig.internalDomains, {'example.org'});
    });
  });

  group('urlFor', () {
    test('joins the tracker URL and a path with exactly one slash', () {
      loadTestEnv(trackerUrl: 'https://tracker.example.org/');

      expect(AppConfig.urlFor('/events/42'), 'https://tracker.example.org/events/42');
      expect(AppConfig.urlFor('events/42'), 'https://tracker.example.org/events/42');
    });

    test('works when TRACKER_URL has no trailing slash', () {
      loadTestEnv(trackerUrl: 'http://localhost:8000');

      expect(AppConfig.urlFor('/events'), 'http://localhost:8000/events');
    });
  });
}
