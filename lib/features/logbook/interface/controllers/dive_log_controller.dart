import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../../domain/repositories/dive_log_repository.dart';
import '../../infrastructure/repositories/firestore_dive_log_repository.dart';
import '../../infrastructure/repositories/in_memory_dive_log_repository.dart';
import '../../usecase/get_dive_logs.dart';
import '../../usecase/save_dive_log.dart';
import '../../usecase/delete_dive_log.dart';
import '../../usecase/upload_dive_log_photo.dart';
import '../../usecase/delete_dive_log_photo.dart';
import '../../../auth/interface/controllers/auth_controller.dart';
import '../../../my_gear/interface/controllers/gear_controller.dart';
import '../../../../core/media/interface/media_providers.dart';
import '../../../../core/monitoring/interface/monitoring_providers.dart';
import '../../../../core/usecase/usecase.dart';

// --- DI Providers ---

/// ログブックリポジトリのProvider
/// ログイン中は FirestoreDiveLogRepository、未ログインやテスト時は InMemoryDiveLogRepository を返却
final diveLogRepositoryProvider = Provider<DiveLogRepository>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser != null) {
    final mediaStorage = ref.watch(mediaStorageRepositoryProvider);
    return FirestoreDiveLogRepository(
      userId: authUser.id,
      mediaStorageRepository: mediaStorage,
    );
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

/// ログ写真アップロードユースケースのProvider
final uploadDiveLogPhotoUseCaseProvider = Provider<UploadDiveLogPhoto>((ref) {
  final mediaRepo = ref.watch(mediaStorageRepositoryProvider);
  return UploadDiveLogPhoto(mediaRepo);
});

/// ログ写真削除ユースケースのProvider
final deleteDiveLogPhotoUseCaseProvider = Provider<DeleteDiveLogPhoto>((ref) {
  final mediaRepo = ref.watch(mediaStorageRepositoryProvider);
  return DeleteDiveLogPhoto(mediaRepo);
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
    return getLogs(const NoParams());
  }

  /// ログを新規作成・保存して一覧状態を更新
  Future<void> addLog(DiveLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final saveLog = ref.read(saveDiveLogUseCaseProvider);
      await saveLog(log);

      // アナリティクスイベント計測
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logDiveLogCreated(
        spotName: log.location,
        maxDepth: log.maxDepthMeter,
        durationMinutes: log.bottomTimeMinutes,
        rating: log.rating,
      );
      final sacRate = log.calculateSacRate();
      if (sacRate > 0) {
        analytics.logSacCalculated(
          sacRate: sacRate,
          avgDepth: log.avgDepthMeter,
          durationMinutes: log.bottomTimeMinutes,
        );
      }

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
