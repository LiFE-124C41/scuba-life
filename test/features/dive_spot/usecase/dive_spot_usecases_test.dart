import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/dive_spot/domain/entities/dive_spot.dart';
import 'package:scuba_life/features/dive_spot/infrastructure/repositories/in_memory_dive_spot_repository.dart';
import 'package:scuba_life/features/dive_spot/usecase/dive_spot_usecases.dart';

void main() {
  group('DiveSpot UseCases Tests', () {
    late InMemoryDiveSpotRepository repository;
    late GetDiveSpotsUseCase getDiveSpotsUseCase;
    late AddDiveSpotUseCase addDiveSpotUseCase;
    late ToggleFavoriteSpotUseCase toggleFavoriteSpotUseCase;

    setUp(() {
      repository = InMemoryDiveSpotRepository();
      getDiveSpotsUseCase = GetDiveSpotsUseCase(repository);
      addDiveSpotUseCase = AddDiveSpotUseCase(repository);
      toggleFavoriteSpotUseCase = ToggleFavoriteSpotUseCase(repository);
    });

    test('【GetDiveSpotsUseCase】初期登録されているダイビングスポット一覧が取得できること', () async {
      // Act
      final spots = await getDiveSpotsUseCase.execute();

      // Assert
      expect(spots, isNotEmpty);
      expect(spots.any((s) => s.name.contains('大瀬崎')), isTrue);
      expect(spots.any((s) => s.name.contains('伊豆海洋公園')), isTrue);
    });

    test('【AddDiveSpotUseCase】新しいダイビングスポットを追加して一覧に反映されること', () async {
      // Arrange
      final newSpot = DiveSpot(
        id: 'test-spot-custom',
        name: '富戸 ヨコバマ',
        area: '静岡県・東伊豆',
        latitude: 34.9125,
        longitude: 139.1432,
        description: 'エントリーしやすく穏やかな人気ビーチポイント。',
      );

      // Act
      await addDiveSpotUseCase.execute(newSpot);
      final spots = await getDiveSpotsUseCase.execute();

      // Assert
      final added = spots.firstWhere((s) => s.id == 'test-spot-custom');
      expect(added.name, '富戸 ヨコバマ');
      expect(added.latitude, 34.9125);
    });

    test('【ToggleFavoriteSpotUseCase】お気に入りフラグが反転して更新されること', () async {
      // Arrange
      final spotsBefore = await getDiveSpotsUseCase.execute();
      final target = spotsBefore.first;
      final initialFavorite = target.isFavorite;

      // Act
      await toggleFavoriteSpotUseCase.execute(target.id);
      final spotsAfter = await getDiveSpotsUseCase.execute();
      final updated = spotsAfter.firstWhere((s) => s.id == target.id);

      // Assert
      expect(updated.isFavorite, !initialFavorite);
    });
  });
}
