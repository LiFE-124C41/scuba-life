/// アプリケーション内でスケジュール・通知されるアイテムのドメインエンティティ
class AppNotificationItem {
  /// 通知の一意な識別ID (32-bit int)
  final int id;

  /// 通知タイトル
  final String title;

  /// 通知本文
  final String body;

  /// 通知配信予定日時
  final DateTime scheduledDate;

  /// 通知タップ時や識別用のペイロード（例: 'gear:123', 'schedule:abc'）
  final String? payload;

  /// Android 通知チャネルID
  final String channelId;

  /// Android 通知チャネル名
  final String channelName;

  /// Android 通知チャネル説明
  final String? channelDescription;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
    this.channelId = 'scuba_safety_reminders',
    this.channelName = '安全リマインダー',
    this.channelDescription = 'ダイビング機材の点検時期やトリップ準備のお知らせ',
  });

  AppNotificationItem copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? scheduledDate,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      payload: payload ?? this.payload,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelDescription: channelDescription ?? this.channelDescription,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotificationItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          scheduledDate == other.scheduledDate &&
          payload == other.payload &&
          channelId == other.channelId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      body.hashCode ^
      scheduledDate.hashCode ^
      payload.hashCode ^
      channelId.hashCode;
}
