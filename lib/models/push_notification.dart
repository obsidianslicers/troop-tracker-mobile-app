/// One entry in the trooper's notification inbox, as the tracker's
/// `/api/push-notifications` endpoint returns it.
class PushNotification {
  final String id;
  final String title;
  final String body;
  final String url;
  final DateTime? readAt;
  final DateTime createdAt;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] as String?;
    return PushNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      url: json['url'] as String,
      readAt: readAt != null ? DateTime.parse(readAt) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  PushNotification copyWith({DateTime? readAt}) {
    return PushNotification(
      id: id,
      title: title,
      body: body,
      url: url,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
