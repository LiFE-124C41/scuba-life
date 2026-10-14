import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/remote_config/domain/entities/app_remote_config.dart';
import 'package:scuba_life/core/remote_config/infrastructure/in_memory_remote_config_repository.dart';
import 'package:scuba_life/features/dive_spot/domain/entities/dive_spot.dart';

void main() {
  group('InMemoryRemoteConfigRepository Tests', () {
    test('初期値がデフォルトの AppRemoteConfig を保持していること', () {
      final repo = InMemoryRemoteConfigRepository();
      final config = repo.getCurrentConfig();

      expect(config.presetDiveSpotsVersion, equals(1));
      expect(config.dynamicDiveSpots, isEmpty);
      expect(config.maintenanceBannerEnabled, isFalse);
      expect(config.maintenanceBannerMessage, isEmpty);
    });

    test('setConfig で設定を更新できること', () async {
      final repo = InMemoryRemoteConfigRepository();
      final newSpot = DiveSpot(
        id: 'new-spot-1',
        name: '沖ノ島',
        area: '千葉県・館山',
        latitude: 34.9912,
        longitude: 139.8211,
      );

      final updatedConfig = const AppRemoteConfig(
        presetDiveSpotsVersion: 2,
        maintenanceBannerEnabled: true,
        maintenanceBannerMessage: '現在定期メンテナンス中です',
      ).copyWith(dynamicDiveSpots: [newSpot]);

      repo.setConfig(updatedConfig);

      final fetched = await repo.fetchAndActivate();
      expect(fetched.presetDiveSpotsVersion, equals(2));
      expect(fetched.maintenanceBannerEnabled, isTrue);
      expect(fetched.maintenanceBannerMessage, equals('現在定期メンテナンス中です'));
      expect(fetched.dynamicDiveSpots, hasLength(1));
      expect(fetched.dynamicDiveSpots.first.name, equals('沖ノ島'));
    });
  });
}
