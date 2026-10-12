import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/marine_life/domain/entities/marine_life_summary.dart';
import 'package:scuba_life/features/marine_life/usecase/get_marine_life_summaries.dart';

// --- DI Providers ---

/// 生き物図鑑ユースケースのProvider
final getMarineLifeSummariesUseCaseProvider =
    Provider<GetMarineLifeSummaries>((ref) {
  final repository = ref.watch(diveLogRepositoryProvider);
  return GetMarineLifeSummaries(repository);
});

// --- State & Notifier ---

/// 生き物図鑑の検索・フィルタ・ソート状態
class MarineLifeFilterState {
  final String searchQuery;
  final int? selectedMonth;
  final MarineLifeSortOrder sortOrder;

  const MarineLifeFilterState({
    this.searchQuery = '',
    this.selectedMonth,
    this.sortOrder = MarineLifeSortOrder.encounterCountDesc,
  });

  MarineLifeFilterState copyWith({
    String? searchQuery,
    int? Function()? selectedMonth,
    MarineLifeSortOrder? sortOrder,
  }) {
    return MarineLifeFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMonth:
          selectedMonth != null ? selectedMonth() : this.selectedMonth,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// 生き物図鑑の検索・フィルター状態を管理するNotifier
class MarineLifeFilterNotifier extends Notifier<MarineLifeFilterState> {
  @override
  MarineLifeFilterState build() => const MarineLifeFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedMonth(int? month) {
    state = state.copyWith(selectedMonth: () => month);
  }

  void setSortOrder(MarineLifeSortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }

  void reset() {
    state = const MarineLifeFilterState();
  }
}

/// フィルター状態管理Provider
final marineLifeFilterNotifierProvider =
    NotifierProvider<MarineLifeFilterNotifier, MarineLifeFilterState>(() {
  return MarineLifeFilterNotifier();
});

// --- Output List Provider ---

/// 生き物サマリー一覧のProvider
///
/// ログ一覧（`diveLogListProvider`）の更新、または検索・フィルター・ソートの変更を
/// リアクティブに検知し、最新の集計結果を提供する。
final marineLifeListProvider =
    FutureProvider.autoDispose<List<MarineLifeSummary>>((ref) async {
  // ログの新規作成・編集・削除時にリアルタイム連動させる
  ref.watch(diveLogListProvider);

  final filter = ref.watch(marineLifeFilterNotifierProvider);
  final useCase = ref.watch(getMarineLifeSummariesUseCaseProvider);

  final params = MarineLifeFilterParams(
    query: filter.searchQuery,
    month: filter.selectedMonth,
    sortOrder: filter.sortOrder,
  );

  return await useCase(params);
});
