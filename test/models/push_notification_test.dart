import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/push_notification.dart';

void main() {
  final json = <String, dynamic>{
    'id': 'abc',
    'title': 'Troop update',
    'body': 'The troop moved to 10 AM',
    'url': '/events/42',
    'read_at': null,
    'created_at': '2026-11-01T10:00:00Z',
  };

  test('fromJson reads an unread notification', () {
    final subject = PushNotification.fromJson(json);

    expect(subject.id, 'abc');
    expect(subject.title, 'Troop update');
    expect(subject.body, 'The troop moved to 10 AM');
    expect(subject.url, '/events/42');
    expect(subject.readAt, isNull);
    expect(subject.createdAt, DateTime.utc(2026, 11, 1, 10));
    expect(subject.isUnread, isTrue);
  });

  test('fromJson reads a read notification', () {
    final subject = PushNotification.fromJson({...json, 'read_at': '2026-11-02T08:30:00Z'});

    expect(subject.readAt, DateTime.utc(2026, 11, 2, 8, 30));
    expect(subject.isUnread, isFalse);
  });

  test('copyWith marks it read and keeps everything else', () {
    final readAt = DateTime.utc(2026, 11, 3);

    final subject = PushNotification.fromJson(json).copyWith(readAt: readAt);

    expect(subject.readAt, readAt);
    expect(subject.id, 'abc');
    expect(subject.title, 'Troop update');
    expect(subject.body, 'The troop moved to 10 AM');
    expect(subject.url, '/events/42');
    expect(subject.createdAt, DateTime.utc(2026, 11, 1, 10));
  });

  test('copyWith without a value keeps the read time', () {
    final read = PushNotification.fromJson({...json, 'read_at': '2026-11-02T08:30:00Z'});

    expect(read.copyWith().readAt, read.readAt);
  });
}
