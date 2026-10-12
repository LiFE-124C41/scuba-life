import '../../../core/usecase/usecase.dart';
import '../domain/entities/dive_log.dart';
import '../domain/repositories/dive_log_repository.dart';

/// ログ一覧を取得するユースケース
class GetDiveLogs implements UseCase<List<DiveLog>, NoParams> {
  final DiveLogRepository _repository;

  GetDiveLogs(this._repository);

  @override
  Future<List<DiveLog>> call(NoParams params) async {
    final logs = await _repository.getAllLogs();
    // 日時降順でソートして返却（変更不能リストへの配慮）
    final sorted = List<DiveLog>.from(logs);
    sorted.sort((a, b) => b.entryTime.compareTo(a.entryTime));
    return sorted;
  }
}
