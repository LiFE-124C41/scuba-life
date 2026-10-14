import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/remote_config/domain/entities/app_remote_config.dart';
import 'package:scuba_life/core/remote_config/infrastructure/in_memory_remote_config_repository.dart';
import 'package:scuba_life/features/dive_spot/domain/entities/dive_spot.dart';
import 'package:scuba_life/features/dive_spot/infrastructure/repositories/in_memory_dive_spot_repository.dart';
import 'package:scuba_life/features/dive_spot/usecase/dive_spot_usecases.dart';

void main() {
  group('GetDiveSpotsUseCase with Remote Config Merging', () {
    late InMemoryDiveSpotRepository spotRepository;
    late InMemoryRemoteConfigRepository remoteConfigRepository;

    setUp(() {
      spotRepository = InMemoryDiveSpotRepository();
      remoteConfigRepository = InMemoryRemoteConfigRepository();
    });

    test('動的スポットがない場合はベーススポットのみが返却されること', () async {
      final useCase = GetDiveSpotsUseCase(spotRepository, remoteConfigRepository);
      final spots = await useCase.execute();

      final baseSpots = await spotRepository.getSpots();
      expect(spots.length, equals(baseSpots.length));
    });

    test('新規の動的スポットが Remote Config から配信された場合、マージされて追加されること', () async {
      final newDynamicSpot = DiveSpot(
        id: 'spot-dynamic-miyake-1',
        name: '三宅島 錆ヶ浜',
        area: '東京都・伊豆諸島',
        latitude: 34.0811,
        longitude: 139.5122,
        description: '溶岩アーチとダイナミックな回遊魚の群れ。',
      );

      remoteConfigRepository.setConfig(
        AppRemoteConfig(
          presetDiveSpotsVersion: 2,
          dynamicDiveSpots: [newDynamicSpot],
        ),
      );

      final useCase = GetDiveSpotsUseCase(spotRepository, remoteConfigRepository);
      final spots = await useCase.execute();

      final baseSpots = await spotRepository.getSpots();
      expect(spots.length, equals(baseSpots.length + 1));
      expect(spots.any((s) => s.id == 'spot-dynamic-miyake-1'), isTrue);
      final found = spots.firstWhere((s) => s.id == 'spot-dynamic-miyake-1');
      expect(found.name, equals('三宅島 錆ヶ浜'));
    });

    test('既存IDのスポットが動的配信された場合、ユーザーのお気に入り状態を保持しつつメタデータが更新されること', () async {
      // 既存スポット「大瀬崎 湾内」(spot-osezaki-1) は defaultPresetSpots で isFavorite: true
      // これを動的スポットで説明文を変更して配信（isFavorite: false で配信されても既存の true が維持される）
      final updatedOsezaki = DiveSpot(
        id: 'spot-osezaki-1',
        name: '大瀬崎 湾内 (最新情報更新)',
        area: '静岡県・西伊豆',
        latitude: 35.0308,
        longitude: 138.7903,
        description: '2026年最新の水中マップ対応済み。',
        isFavorite: false, // リモート側は未設定
      );

      remoteConfigRepository.setConfig(
        AppRemoteConfig(
          presetDiveSpotsVersion: 3,
          dynamicDiveSpots: [updatedOsezaki],
        ),
      );

      final useCase = GetDiveSpotsUseCase(spotRepository, remoteConfigRepository);
      final spots = await useCase.execute();

      final osezaki = spots.firstWhere((s) => s.id == 'spot-osezaki-1');
      expect(osezaki.name, equals('大瀬崎 湾内 (最新情報更新)'));
      expect(osezaki.description, equals('2026年最新の水中マップ対応済み。'));
      expect(osezaki.isFavorite, isTrue); // ユーザーのお気に入りが保持される
    });

    test('RemoteConfigRepository が null の場合でも安全にベーススポットが返却されること', () async {
      final useCase = GetDiveSpotsUseCase(spotRepository, null);
      final spots = await useCase.execute();

      expect(spots, isNotEmpty);
    });
  });
}
