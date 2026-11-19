import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/notifications_controller.dart';
import 'package:tt_mobile_app/models/push_notification.dart';

import '../support/fake_notification_api.dart';

void main() {
  late FakeNotificationApi api;
  late List<int> badges;
  late NotificationsController subject;
  late int notifications;
  final now = DateTime.utc(2026, 11, 19, 12);

  setUp(() {
    api = FakeNotificationApi([
      notification('1'),
      notification('2'),
      notification('3', readAt: DateTime.utc(2026, 11, 1)),
    ]);
    badges = [];
    subject = NotificationsController(
      api: api,
      updateBadge: (count) async => badges.add(count),
      now: () => now,
    );
    notifications = 0;
    subject.addListener(() => notifications++);
  });

  test('starts empty and not loading', () {
    expect(subject.notifications, isEmpty);
    expect(subject.isLoading, isFalse);
    expect(subject.unreadCount, 0);
  });

  test('refresh loads the inbox and sets the badge to the unread count', () async {
    final future = subject.refresh();
    expect(subject.isLoading, isTrue);
    await future;

    expect(subject.isLoading, isFalse);
    expect(subject.notifications.map((n) => n.id), ['1', '2', '3']);
    expect(subject.unreadCount, 2);
    expect(badges, [2]);
    expect(notifications, 2);
  });

  test('markRead marks it read on the tracker and here', () async {
    await subject.refresh();

    await subject.markRead(subject.notifications.first);

    expect(api.markedRead, ['1']);
    expect(subject.notifications.first.readAt, now);
    expect(subject.notifications[1].isUnread, isTrue);
    expect(subject.unreadCount, 1);
    expect(badges.last, 1);
  });

  test('markRead skips a notification that is already read', () async {
    await subject.refresh();
    final before = notifications;

    await subject.markRead(subject.notifications.last);

    expect(api.markedRead, isEmpty);
    expect(notifications, before);
  });

  test('clearAll empties the inbox on the tracker and here', () async {
    await subject.refresh();

    await subject.clearAll();

    expect(api.cleared, 1);
    expect(subject.notifications, isEmpty);
    expect(badges.last, 0);
  });

  test('clearForLogout empties the inbox here only', () async {
    await subject.refresh();

    await subject.clearForLogout();

    expect(api.cleared, 0);
    expect(subject.notifications, isEmpty);
    expect(badges.last, 0);
  });

  test('a device without badge support still refreshes', () async {
    subject = NotificationsController(
      api: api,
      updateBadge: (_) async => throw UnsupportedError('no badges'),
    );

    await subject.refresh();

    expect(subject.notifications, hasLength(3));
  });

  test('builds its real dependencies by default', () {
    expect(NotificationsController(), isA<NotificationsController>());
  });
}

PushNotification notification(String id, {DateTime? readAt}) => PushNotification(
      id: id,
      title: 'Title $id',
      body: 'Body $id',
      url: '/events/$id',
      readAt: readAt,
      createdAt: DateTime.utc(2026, 11, 1),
    );
