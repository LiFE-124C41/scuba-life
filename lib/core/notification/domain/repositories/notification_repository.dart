import '../entities/app_notification_item.dart';

/// 通知基盤の抽象リポジトリインターフェース (Pure Dart)
abstract class NotificationRepository {
  /// 通知システムの初期化
  Future<void> initialize();

  /// 端末の通知権限をリクエスト
  /// 許可された場合は true、拒否または未対応の場合は false
  Future<bool> requestPermission();

  /// 指定日時に通知をスケジュール登録
  Future<void> scheduleNotification(AppNotificationItem notification);

  /// 即時通知を表示
  Future<void> showNotification(AppNotificationItem notification);

  /// 指定IDの通知スケジュールをキャンセル
  Future<void> cancelNotification(int id);

  /// すべての保留中・スケジュール済み通知をキャンセル
  Future<void> cancelAllNotifications();

  /// 現在スケジュールされている通知一覧を取得
  Future<List<AppNotificationItem>> getPendingNotifications();
}
