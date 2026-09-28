import '../../../core/usecase/usecase.dart';
import '../domain/repositories/dive_log_repository.dart';

/// ダイビングログを削除するユースケース
class DeleteDiveLog implements UseCase<void, String> {
  final DiveLogRepository repository;

  DeleteDiveLog(this.repository);

  @override
  Future<void> call(String id) async {
    await repository.deleteLog(id);
  }
}
