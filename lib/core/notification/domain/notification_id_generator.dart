/// 通知IDを決定・生成するヘルパークラス
class NotificationIdGenerator {
  /// 機材OHリマインダー用の32bit通知ID（1,000,000〜1,899,999）
  static int forGear(String gearId) {
    return 1000000 + (gearId.hashCode.abs() % 900000);
  }

  /// トリップ前日準備リマインダー用の32bit通知ID（2,000,000〜2,899,999）
  static int forSchedule(String scheduleId) {
    return 2000000 + (scheduleId.hashCode.abs() % 900000);
  }

  /// リモートプッシュ通知（FCM）用の32bit通知ID（3,000,000〜3,899,999）
  static int forPushMessage(String? messageId) {
    if (messageId == null || messageId.isEmpty) return 3000000;
    return 3000000 + (messageId.hashCode.abs() % 900000);
  }

  /// テスト通知用のID
  static const int testNotificationId = 999999;
}
