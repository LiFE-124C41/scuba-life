/// リモートプッシュ通知（FCM）メッセージのドメインエンティティ
class PushNotificationMessage {
  final String? id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String category;
  final DateTime receivedAt;

  const PushNotificationMessage({
    this.id,
    required this.title,
    required this.body,
    this.data = const {},
    this.category = 'general',
    required this.receivedAt,
  });

  /// FCM の RemoteMessage や JSON からのファクトリ生成
  factory PushNotificationMessage.fromMap({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? sentTime,
  }) {
    final payloadData = data ?? {};
    final cat = (payloadData['category'] as String?)?.toLowerCase() ??
        (payloadData['type'] as String?)?.toLowerCase() ??
        'general';

    return PushNotificationMessage(
      id: id,
      title: title ?? (payloadData['title'] as String?) ?? 'Scuba Life',
      body: body ?? (payloadData['body'] as String?) ?? '',
      data: payloadData,
      category: cat,
      receivedAt: sentTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'category': category,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushNotificationMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          category == other.category;

  @override
  int get hashCode => Object.hash(id, title, body, category);
}
