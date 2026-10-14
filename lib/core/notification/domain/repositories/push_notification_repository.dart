import '../entities/push_notification_message.dart';

/// リモートプッシュ通知基盤の抽象リポジトリインターフェース (Pure Dart)
abstract class PushNotificationRepository {
  /// プッシュ通知基盤の初期化（ハンドラ登録・トピック自動設定）
  Future<void> initialize();

  /// 端末のプッシュ通知権限をリクエスト
  Future<bool> requestPermission();

  /// FCMデバイストークンを取得
  Future<String?> getToken();

  /// FCMトークン更新ストリーム
  Stream<String> get onTokenRefresh;

  /// 特定のトピックを購読（例: 'weather_alerts', 'announcements'）
  Future<void> subscribeToTopic(String topic);

  /// 特定のトピックの購読を解除
  Future<void> unsubscribeFromTopic(String topic);

  /// フォアグラウンド受信メッセージのストリーム
  Stream<PushNotificationMessage> get onMessage;

  /// 通知タップ起動時のメッセージストリーム
  Stream<PushNotificationMessage> get onMessageOpenedApp;

  /// アプリ終了状態から通知タップで起動された際の初期メッセージを取得
  Future<PushNotificationMessage?> getInitialMessage();
}
