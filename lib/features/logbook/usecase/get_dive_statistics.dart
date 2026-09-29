import '../../../core/usecase/usecase.dart';
import '../domain/entities/dive_statistics.dart';
import '../domain/repositories/dive_log_repository.dart';

/// ダイバー統計・スキル指標を取得するユースケース
///
/// ログブックリポジトリからログ全件を取得し、
/// インストラクター提示用の統計サマリー（`DiveStatistics`）を生成して返却する。
class GetDiveStatistics implements UseCase<DiveStatistics, NoParams> {
  final DiveLogRepository _repository;

  GetDiveStatistics(this._repository);

  @override
  Future<DiveStatistics> call(NoParams params) async {
    final logs = await _repository.getAllLogs();
    return DiveStatistics.fromLogs(logs);
  }
}
