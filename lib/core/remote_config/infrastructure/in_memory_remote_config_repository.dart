import '../domain/entities/app_remote_config.dart';
import '../domain/repositories/remote_config_repository.dart';

/// テストおよびオフライン・初期環境用のインメモリ Remote Config リポジトリ
class InMemoryRemoteConfigRepository implements RemoteConfigRepository {
  AppRemoteConfig _config;
  bool isInitialized = false;

  InMemoryRemoteConfigRepository([AppRemoteConfig? initialConfig])
      : _config = initialConfig ?? const AppRemoteConfig();

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<AppRemoteConfig> fetchAndActivate() async {
    return _config;
  }

  @override
  AppRemoteConfig getCurrentConfig() {
    return _config;
  }

  /// テスト用の設定更新メソッド
  void setConfig(AppRemoteConfig config) {
    _config = config;
  }
}
