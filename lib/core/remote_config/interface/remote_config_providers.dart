import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_remote_config.dart';
import '../domain/repositories/remote_config_repository.dart';
import '../infrastructure/firebase_remote_config_repository.dart';

/// Remote Config リポジトリプロバイダー
final remoteConfigRepositoryProvider =
    Provider<RemoteConfigRepository>((ref) {
  return FirebaseRemoteConfigRepository();
});

/// Remote Config の状態Notifier
class RemoteConfigNotifier extends Notifier<AppRemoteConfig> {
  @override
  AppRemoteConfig build() {
    final repo = ref.watch(remoteConfigRepositoryProvider);
    // 初期値として現在のキャッシュを返す
    final initial = repo.getCurrentConfig();

    // バックグラウンドで最新値をフェッチ & アクティベート
    Future.microtask(() => fetchAndActivate());
    return initial;
  }

  Future<void> fetchAndActivate() async {
    try {
      final repo = ref.read(remoteConfigRepositoryProvider);
      final latest = await repo.fetchAndActivate();
      state = latest;
    } catch (_) {
      // オフライン時等はキャッシュ/デフォルトのまま
    }
  }

  /// メンテナンスバナーを一時的に閉じる（セッション限りの非表示用）
  void dismissBanner() {
    state = state.copyWith(maintenanceBannerEnabled: false);
  }
}

final remoteConfigNotifierProvider =
    NotifierProvider<RemoteConfigNotifier, AppRemoteConfig>(() {
  return RemoteConfigNotifier();
});
