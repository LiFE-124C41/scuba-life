import '../../../core/usecase/usecase.dart';
import '../domain/entities/dive_log.dart';
import '../domain/repositories/dive_log_repository.dart';

/// ログを保存・更新するユースケース
class SaveDiveLog implements UseCase<void, DiveLog> {
  final DiveLogRepository _repository;

  SaveDiveLog(this._repository);

  @override
  Future<void> call(DiveLog log) async {
    await _repository.saveLog(log);
  }
}
