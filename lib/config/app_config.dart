import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single source of truth for all app-wide configuration.
/// Change the URL, colors, or name here — nowhere else.
class AppConfig {
  AppConfig._();

  static const String appName = 'Troop Tracker';

  // The Tracker site loaded in the WebView.
  // Set TRACKER_URL in .env (copy .env.example → .env and edit).
  // Physical device against local server: use your Mac's LAN IP, e.g. http://192.168.1.x:8000/
  // Android emulator: http://10.0.2.2:8000/
  static String get trackerUrl =>
      dotenv.env['TRACKER_URL'] ?? 'https://tracker.fl501st.com/';

  // Derived from trackerUrl — no need to change this manually.
  // "test.fl501st.com" → "fl501st.com", "localhost" → "localhost", "192.168.x.x" → the IP.
  static String get trackerDomain {
    final host = Uri.parse(trackerUrl).host;
    if (host == 'localhost' || RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
      return host;
    }
    final segments = host.split('.');
    return segments.length >= 2
        ? segments.sublist(segments.length - 2).join('.')
        : host;
  }

  // All domains that should stay inside the WebView.
  // fl501st.com is always internal so forum/site links don't open externally during local dev.
  static Set<String> get internalDomains => {
        'fl501st.com',
        'redirectmeto.com',
        trackerDomain,
      };

  // Dark navy — used for splash background and WebView background
  static const Color splashBackgroundColor = Color(0xFF00131F);

  // Primary brand blue — used for progress indicators and theme seed
  static const Color primaryColor = Color(0xFF006899);
}
