import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/gear_item.dart';
import '../../domain/repositories/gear_repository.dart';
import '../../../auth/interface/controllers/auth_controller.dart';
import '../../infrastructure/repositories/firestore_gear_repository.dart';
import '../../infrastructure/repositories/in_memory_gear_repository.dart';
import '../../usecase/decrement_gear_dives.dart';
import '../../usecase/delete_gear_item.dart';
import '../../usecase/get_gear_items.dart';
import '../../usecase/increment_gear_dives.dart';
import '../../usecase/record_overhaul.dart';
import '../../usecase/save_gear_item.dart';

/// リポジトリプロバイダー
/// ログイン中は FirestoreGearRepository、未ログインやテスト時は InMemoryGearRepository を返却
final gearRepositoryProvider = Provider<GearRepository>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser != null) {
    return FirestoreGearRepository(userId: authUser.id);
  }
  return InMemoryGearRepository();
});

/// ユースケースプロバイダー群
final getGearItemsUseCaseProvider = Provider<GetGearItems>((ref) {
  final repo = ref.watch(gearRepositoryProvider);
  return GetGearItems(repo);
});

final saveGearItemUseCaseProvider = Provider<SaveGearItem>((ref) {
  final repo = ref.watch(gearRepositoryProvider);
  return SaveGearItem(repo);
});

final deleteGearItemUseCaseProvider = Provider<DeleteGearItem>((ref) {
  final repo = ref.watch(gearRepositoryProvider);
  return DeleteGearItem(repo);
});

final recordOverhaulUseCaseProvider = Provider<RecordOverhaul>((ref) {
  final repo = ref.watch(gearRepositoryProvider);
  return RecordOverhaul(repo);
});

final incrementGearDivesUseCaseProvider = Provider<IncrementGearDives>((ref) {
  final repo = ref.watch(gearRepositoryProvider);
  return IncrementGearDives(repo);
});

final decrementGearDivesUseCaseProvider = Provider<DecrementGearDives>((ref) {
  final repo = ref.watch(gearRepositoryProvider);
  return DecrementGearDives(repo);
});

/// 機材管理画面の状態クラス
class GearListState {
  final List<GearItem> allItems;
  final GearCategory? selectedCategory;
  final bool isLoading;
  final Object? error;

  const GearListState({
    this.allItems = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
  });

  GearListState copyWith({
    List<GearItem>? allItems,
    GearCategory? Function()? selectedCategory,
    bool? isLoading,
    Object? error,
  }) {
    return GearListState(
      allItems: allItems ?? this.allItems,
      selectedCategory:
          selectedCategory != null ? selectedCategory() : this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// フィルター適用後の機材一覧
  List<GearItem> get filteredItems {
    if (selectedCategory == null) {
      return allItems;
    }
    return allItems.where((item) => item.category == selectedCategory).toList();
  }

  /// 要オーバーホール件数
  int get overdueCount =>
      allItems.where((g) => g.calculateStatus() == OverhaulStatus.overdue).length;

  /// もうすぐ推奨時期件数
  int get warningCount =>
      allItems.where((g) => g.calculateStatus() == OverhaulStatus.warning).length;

  /// 良好件数
  int get goodCount =>
      allItems.where((g) => g.calculateStatus() == OverhaulStatus.good).length;
}

/// 機材一覧Notifier
class GearListNotifier extends Notifier<GearListState> {
  @override
  GearListState build() {
    // 初期ロード
    Future.microtask(() => loadGear());
    return const GearListState(isLoading: true);
  }

  Future<void> loadGear() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final getItems = ref.read(getGearItemsUseCaseProvider);
      final items = await getItems(const NoParams());
      state = state.copyWith(allItems: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void setCategoryFilter(GearCategory? category) {
    state = state.copyWith(selectedCategory: () => category);
  }

  Future<void> saveGear(GearItem gear) async {
    try {
      final saveItem = ref.read(saveGearItemUseCaseProvider);
      await saveItem(gear);
      await loadGear();
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  Future<void> deleteGear(String id) async {
    try {
      final deleteItem = ref.read(deleteGearItemUseCaseProvider);
      await deleteItem(id);
      await loadGear();
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  Future<GearItem> recordOverhaul({
    required String gearId,
    required DateTime overhaulDate,
    String? memo,
  }) async {
    try {
      final recordUseCase = ref.read(recordOverhaulUseCaseProvider);
      final updated = await recordUseCase(
        RecordOverhaulParams(
          gearId: gearId,
          overhaulDate: overhaulDate,
          memo: memo,
        ),
      );
      await loadGear();
      return updated;
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  Future<void> incrementGearDives(List<String> gearIds) async {
    try {
      final incrementUseCase = ref.read(incrementGearDivesUseCaseProvider);
      await incrementUseCase(gearIds);
      await loadGear();
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  Future<void> decrementGearDives(List<String> gearIds) async {
    try {
      final decrementUseCase = ref.read(decrementGearDivesUseCaseProvider);
      await decrementUseCase(gearIds);
      await loadGear();
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }
}

final gearListNotifierProvider =
    NotifierProvider<GearListNotifier, GearListState>(() {
  return GearListNotifier();
});
