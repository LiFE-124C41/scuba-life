import '../entities/notification_settings.dart';

/// 通知設定の永続化リポジトリインターフェース (Pure Dart)
abstract class NotificationSettingsRepository {
  /// 現在の通知設定を読み込む
  Future<NotificationSettings> loadSettings();

  /// 通知設定を保存する
  Future<void> saveSettings(NotificationSettings settings);
}
