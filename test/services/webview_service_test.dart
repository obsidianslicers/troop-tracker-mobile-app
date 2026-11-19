import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/services/webview_service.dart';

void main() {
  group('isInternalUrl', () {
    test('keeps the tracker domain and its subdomains in the app', () {
      dotenv.testLoad(fileInput: 'TRACKER_URL=https://test.example.org/');

      expect(WebViewService.isInternalUrl('https://test.example.org/events'), isTrue);
      expect(WebViewService.isInternalUrl('https://example.org/forum/'), isTrue);
      expect(WebViewService.isInternalUrl('https://www.Example.org/'), isTrue);
    });

    test('opens a lookalike domain outside the app', () {
      dotenv.testLoad(fileInput: 'TRACKER_URL=https://test.example.org/');

      expect(WebViewService.isInternalUrl('https://evilexample.org/'), isFalse);
      expect(WebViewService.isInternalUrl('https://example.org.evil.com/'), isFalse);
      expect(WebViewService.isInternalUrl('https://www.google.com/maps'), isFalse);
    });

    test('keeps the INTERNAL_DOMAINS in the app', () {
      dotenv.testLoad(
        fileInput: 'TRACKER_URL=http://localhost:8000/\n'
            'INTERNAL_DOMAINS= forum.example.net , Example.com,',
      );

      expect(WebViewService.isInternalUrl('http://localhost:8000/events'), isTrue);
      expect(WebViewService.isInternalUrl('https://forum.example.net/threads/1'), isTrue);
      expect(WebViewService.isInternalUrl('https://www.example.com/'), isTrue);
      expect(WebViewService.isInternalUrl('https://example.net/'), isFalse);
    });

    test('no longer treats fl501st.com as internal unless configured', () {
      dotenv.testLoad(fileInput: 'TRACKER_URL=https://test.example.org/');

      expect(WebViewService.isInternalUrl('https://www.fl501st.com/'), isFalse);
    });
  });
}
