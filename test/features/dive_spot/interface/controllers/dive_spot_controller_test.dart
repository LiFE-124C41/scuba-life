import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/dive_spot/domain/entities/dive_spot.dart';
import 'package:scuba_life/features/dive_spot/interface/controllers/dive_spot_controller.dart';

void main() {
  group('DiveSpotListNotifier Riverpod Controller Tests', () {
    test('初期化時に初期スポットリストがAsyncDataとして取得されること', () async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final spots = await container.read(diveSpotListProvider.future);

      // Assert
      expect(spots, isNotEmpty);
      expect(container.read(diveSpotListProvider).hasValue, isTrue);
    });

    test('addSpot で新しいスポットが追加され状態が更新されること', () async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(diveSpotListProvider.future);

      final newSpot = DiveSpot(
        id: 'new-spot-controller-test',
        name: '田子 白崎',
        area: '静岡県・西伊豆',
        latitude: 34.8010,
        longitude: 138.7520,
      );

      // Act
      await container.read(diveSpotListProvider.notifier).addSpot(newSpot);
      final currentList = container.read(diveSpotListProvider).value!;

      // Assert
      expect(currentList.any((s) => s.id == 'new-spot-controller-test'), isTrue);
    });

    test('toggleFavorite でスポットのお気に入り状態が反転更新されること', () async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final initialSpots = await container.read(diveSpotListProvider.future);
      final target = initialSpots.first;
      final initialStatus = target.isFavorite;

      // Act
      await container.read(diveSpotListProvider.notifier).toggleFavorite(target.id);
      final updatedSpots = container.read(diveSpotListProvider).value!;
      final updated = updatedSpots.firstWhere((s) => s.id == target.id);

      // Assert
      expect(updated.isFavorite, !initialStatus);
    });
  });
}
