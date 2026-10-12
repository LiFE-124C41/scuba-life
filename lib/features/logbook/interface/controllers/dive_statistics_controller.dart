import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_statistics.dart';
import '../../usecase/get_dive_statistics.dart';
import 'dive_log_controller.dart';

/// ダイバー統計取得ユースケースのProvider
final getDiveStatisticsUseCaseProvider = Provider<GetDiveStatistics>((ref) {
  final repository = ref.watch(diveLogRepositoryProvider);
  return GetDiveStatistics(repository);
});

/// ダイバー統計情報を提供するProvider
///
/// [diveLogListProvider] をリアクティブに監視し、ログの追加・変更・削除時に
/// 自動で最新の統計指標（`DiveStatistics`）を再計算してUIに届ける。
final diveStatisticsProvider = Provider<AsyncValue<DiveStatistics>>((ref) {
  final logsAsync = ref.watch(diveLogListProvider);

  return logsAsync.when(
    data: (logs) => AsyncData(DiveStatistics.fromLogs(logs)),
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
  );
});
