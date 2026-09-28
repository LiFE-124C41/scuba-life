import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_spot.dart';
import '../../domain/repositories/dive_spot_repository.dart';
import '../../infrastructure/repositories/in_memory_dive_spot_repository.dart';
import '../../usecase/dive_spot_usecases.dart';

// リポジトリプロバイダー
final diveSpotRepositoryProvider = Provider<DiveSpotRepository>((ref) {
  return InMemoryDiveSpotRepository();
});

// ユースケースプロバイダー
final getDiveSpotsUseCaseProvider = Provider<GetDiveSpotsUseCase>((ref) {
  final repository = ref.watch(diveSpotRepositoryProvider);
  return GetDiveSpotsUseCase(repository);
});

final addDiveSpotUseCaseProvider = Provider<AddDiveSpotUseCase>((ref) {
  final repository = ref.watch(diveSpotRepositoryProvider);
  return AddDiveSpotUseCase(repository);
});

final toggleFavoriteSpotUseCaseProvider =
    Provider<ToggleFavoriteSpotUseCase>((ref) {
  final repository = ref.watch(diveSpotRepositoryProvider);
  return ToggleFavoriteSpotUseCase(repository);
});

/// ダイビングポイント一覧を管理するNotifier
class DiveSpotListNotifier extends AsyncNotifier<List<DiveSpot>> {
  @override
  Future<List<DiveSpot>> build() async {
    final useCase = ref.watch(getDiveSpotsUseCaseProvider);
    return await useCase.execute();
  }

  /// 新しいポイントを追加
  Future<void> addSpot(DiveSpot spot) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(addDiveSpotUseCaseProvider);
      await useCase.execute(spot);
      final getUseCase = ref.read(getDiveSpotsUseCaseProvider);
      return await getUseCase.execute();
    });
  }

  /// お気に入り切り替え
  Future<void> toggleFavorite(String id) async {
    final currentList = state.value ?? [];
    // 楽観的更新
    state = AsyncValue.data(
      currentList.map((spot) {
        if (spot.id == id) {
          return spot.copyWith(isFavorite: !spot.isFavorite);
        }
        return spot;
      }).toList(),
    );

    try {
      final useCase = ref.read(toggleFavoriteSpotUseCaseProvider);
      await useCase.execute(id);
    } catch (e, st) {
      // 失敗した場合は再取得して復帰
      state = AsyncValue.error(e, st);
      final getUseCase = ref.read(getDiveSpotsUseCaseProvider);
      state = AsyncValue.data(await getUseCase.execute());
    }
  }
}

final diveSpotListProvider =
    AsyncNotifierProvider<DiveSpotListNotifier, List<DiveSpot>>(() {
  return DiveSpotListNotifier();
});
