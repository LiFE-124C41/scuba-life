import '../entities/app_remote_config.dart';

/// Remote Config 操作の抽象リポジトリインターフェース (Pure Dart)
abstract class RemoteConfigRepository {
  /// Remote Config の初期化（デフォルト値やフェッチ間隔の設定）
  Future<void> initialize();

  /// 最新の設定をフェッチしてアクティベートし、最新の AppRemoteConfig を返却
  Future<AppRemoteConfig> fetchAndActivate();

  /// 現在キャッシュされている AppRemoteConfig を同期的に取得
  AppRemoteConfig getCurrentConfig();
}
