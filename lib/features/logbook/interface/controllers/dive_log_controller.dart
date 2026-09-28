import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../../domain/repositories/dive_log_repository.dart';
import '../../infrastructure/repositories/in_memory_dive_log_repository.dart';
import '../../usecase/get_dive_logs.dart';
import '../../usecase/save_dive_log.dart';
import '../../../../core/usecase/usecase.dart';

// --- DI Providers ---

/// ログブックリポジトリのProvider
/// テスト時や他インフラ実装への差し替えは overrides で容易に行える
final diveLogRepositoryProvider = Provider<DiveLogRepository>((ref) {
  return InMemoryDiveLogRepository();
});

/// ログ一覧取得ユースケースのProvider
final getDiveLogsUseCaseProvider = Provider<GetDiveLogs>((ref) {
  final repository = ref.watch(diveLogRepositoryProvider);
  return GetDiveLogs(repository);
});

/// ログ保存ユースケースのProvider
final saveDiveLogUseCaseProvider = Provider<SaveDiveLog>((ref) {
  final repository = ref.watch(diveLogRepositoryProvider);
  return SaveDiveLog(repository);
});

// --- State Controller (Notifier) ---

/// ログ一覧の状態管理コントローラー
///
/// AsyncNotifier を採用し、ローディング・成功データ・エラー状態を一元管理する。
/// ビジネスロジックそのものは保持せず、ユースケースを呼び出す責務に専念する。
class DiveLogListNotifier extends AsyncNotifier<List<DiveLog>> {
  @override
  Future<List<DiveLog>> build() async {
    final getLogs = ref.watch(getDiveLogsUseCaseProvider);
    final logs = await getLogs(const NoParams());
    
    // 初期表示用のサンプルデータが空の場合は1件投入
    if (logs.isEmpty) {
      final saveLog = ref.read(saveDiveLogUseCaseProvider);
      final initialLog = DiveLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        entryTime: DateTime.now().subtract(const Duration(hours: 2)),
        exitTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        maxDepthMeter: 18.5,
        avgDepthMeter: 12.0,
        startPressureBar: 200,
        endPressureBar: 50,
        location: '伊豆・大瀬崎（湾内）',
        notes: '透明度良好。ミノカサゴ、クマノミのペアを観察。',
      );
      await saveLog(initialLog);
      return await getLogs(const NoParams());
    }

    return logs;
  }

  /// ログを新規作成・保存して一覧状態を更新
  Future<void> addLog(DiveLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final saveLog = ref.read(saveDiveLogUseCaseProvider);
      await saveLog(log);
      final getLogs = ref.read(getDiveLogsUseCaseProvider);
      return await getLogs(const NoParams());
    });
  }
}

/// ログ一覧NotifierのProvider
final diveLogListProvider =
    AsyncNotifierProvider<DiveLogListNotifier, List<DiveLog>>(() {
  return DiveLogListNotifier();
});
