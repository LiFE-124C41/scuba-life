import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../../domain/repositories/dive_log_repository.dart';
import '../../infrastructure/repositories/firestore_dive_log_repository.dart';
import '../../infrastructure/repositories/in_memory_dive_log_repository.dart';
import '../../usecase/get_dive_logs.dart';
import '../../usecase/save_dive_log.dart';
import '../../usecase/delete_dive_log.dart';
import '../../../auth/interface/controllers/auth_controller.dart';
import '../../../my_gear/interface/controllers/gear_controller.dart';
import '../../../../core/usecase/usecase.dart';

// --- DI Providers ---

/// ログブックリポジトリのProvider
/// ログイン中は FirestoreDiveLogRepository、未ログインやテスト時は InMemoryDiveLogRepository を返却
final diveLogRepositoryProvider = Provider<DiveLogRepository>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser != null) {
    return FirestoreDiveLogRepository(userId: authUser.id);
  }
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

/// ログ削除ユースケースのProvider
final deleteDiveLogUseCaseProvider = Provider<DeleteDiveLog>((ref) {
  final repository = ref.watch(diveLogRepositoryProvider);
  return DeleteDiveLog(repository);
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
        scheduleId: 'sch-1',
        entryTime: DateTime.now().subtract(const Duration(hours: 2)),
        exitTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        location: '伊豆・大瀬崎（湾内）',
        spotId: 'spot-osezaki-1',
        latitude: 35.0308,
        longitude: 138.7903,
        diveCenter: '大瀬ダイバーズステーション',
        rating: 5,
        divePurpose: 'ファンダイビング',
        entryMethod: 'ビーチ',
        waterArea: '海洋',
        waterType: '海水',
        maxDepthMeter: 18.5,
        avgDepthMeter: 12.0,
        startPressureBar: 200,
        endPressureBar: 50,
        tankVolumeLiter: 10.0,
        cylinderMaterial: 'スチール',
        weightKg: 4.0,
        plannedDepthMeter: 20.0,
        plannedDurationMinutes: 45,
        plannedReservePressureBar: 50.0,
        weather: '晴れ',
        airTemp: 26.0,
        waterTempMin: 21.0,
        waterTempMax: 23.5,
        visibilityMeter: 15.0,
        underwaterCurrent: '弱',
        surfaceCurrent: '穏やか',
        tideType: '中潮',
        highTideTime1: '06:15',
        lowTideTime1: '12:30',
        highTideTime2: '18:45',
        lowTideTime2: '00:40',
        buddies: ['佐藤インストラクター', '鈴木ダイバー'],
        marineLife: ['ミノカサゴ', 'クマノミ', 'ウミウシ', 'アオリイカ'],
        equipment: '5mmウェットスーツ, フードベスト, スントD5',
        notes: '透明度良好で青い海。アオリイカの群れとクマノミのペアをじっくり観察できました。',
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

  /// ログを削除して一覧状態を更新
  ///
  /// 対象ログに紐付く機材がある場合、機材のダイブ本数を自動で1減算（デクリメント）して元に戻す。
  Future<void> deleteLog(String logId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getLogs = ref.read(getDiveLogsUseCaseProvider);
      final currentLogs = await getLogs(const NoParams());
      final targetLog = currentLogs.where((l) => l.id == logId).firstOrNull;

      // 1. ログの削除を実行
      final deleteUseCase = ref.read(deleteDiveLogUseCaseProvider);
      await deleteUseCase(logId);

      // 2. ログに登録されていた機材のダイブ本数を減算（巻き戻し）
      if (targetLog != null && targetLog.selectedGearIds.isNotEmpty) {
        await ref
            .read(gearListNotifierProvider.notifier)
            .decrementGearDives(targetLog.selectedGearIds);
      }

      return await getLogs(const NoParams());
    });
  }
}

/// ログ一覧NotifierのProvider
final diveLogListProvider =
    AsyncNotifierProvider<DiveLogListNotifier, List<DiveLog>>(() {
  return DiveLogListNotifier();
});
