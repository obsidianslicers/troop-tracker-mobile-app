// A stand-in Troop Tracker for the e2e tests in integration_test/.
//
//   dart run tool/mock_tracker.dart [port]     (default port 8080)
//
// It serves pages that report the sign-in state the way the real tracker does
// (window.__authState), the push notification inbox API, and /__test/ routes
// the tests use to sign in, reset, and see which requests the app made.
import 'dart:convert';
import 'dart:io';

final _requests = <String>[];
var _signedIn = false;
var _inbox = _freshInbox();

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args.first) : 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Mock tracker listening on http://localhost:$port/');
  await for (final request in server) {
    await _handle(request);
  }
}

Future<void> _handle(HttpRequest request) async {
  final method = request.method;
  final path = request.uri.path;
  if (!path.startsWith('/__test/')) _requests.add('$method $path');
  stdout.writeln('$method $path');

  final response = request.response;
  if (path == '/__test/sign-in' && method == 'POST') {
    _signedIn = true;
    return _send(response, 204);
  }
  if (path == '/__test/reset' && method == 'POST') {
    _signedIn = false;
    _inbox = _freshInbox();
    _requests.clear();
    return _send(response, 204);
  }
  if (path == '/__test/reset-requests' && method == 'POST') {
    _requests.clear();
    return _send(response, 204);
  }
  if (path == '/__test/requests') {
    return _sendJson(response, _requests);
  }
  if (path == '/api/push-notifications') {
    if (!_signedIn) return _send(response, 401);
    if (method == 'DELETE') {
      _inbox.clear();
      return _send(response, 204);
    }
    return _sendJson(response, _inbox);
  }
  final read = RegExp(r'^/api/push-notifications/([^/]+)/read$').firstMatch(path);
  if (read != null && method == 'POST') {
    for (final notification in _inbox.where((n) => n['id'] == read.group(1))) {
      notification['read_at'] = DateTime.now().toUtc().toIso8601String();
    }
    return _send(response, 204);
  }
  return _sendPage(response, path);
}

Future<void> _sendPage(HttpResponse response, String path) async {
  response.headers.contentType = ContentType.html;
  response.write('''<!doctype html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body>
<h1>Mock Troop Tracker</h1>
<p>Page: $path</p>
<script>window.__authState = $_signedIn;</script>
</body></html>''');
  await response.close();
}

Future<void> _sendJson(HttpResponse response, Object body) async {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

Future<void> _send(HttpResponse response, int status) async {
  response.statusCode = status;
  await response.close();
}

List<Map<String, Object?>> _freshInbox() {
  final now = DateTime.now().toUtc();
  return [
    {
      'id': '1',
      'title': 'Troop posted',
      'body': 'Sign up for the hospital visit',
      'url': '/events/42',
      'read_at': null,
      'created_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),
    },
    {
      'id': '2',
      'title': 'Costume approved',
      'body': 'Your TK is approved',
      'url': '/account/costumes',
      'read_at': now.toIso8601String(),
      'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];
}
