import '../../domain/entities/dive_log.dart';
import '../../domain/repositories/dive_log_repository.dart';

/// インメモリのログブックリポジトリ実装
///
/// 開発初期のプロトタイプやローカル検証用。
/// 本番ではSQLiteやIsar、Cloud Firestore等へ差し替えることが可能。
class InMemoryDiveLogRepository implements DiveLogRepository {
  final Map<String, DiveLog> _storage = {};

  @override
  Future<List<DiveLog>> getAllLogs() async {
    return _storage.values.toList();
  }

  @override
  Future<DiveLog?> getLogById(String id) async {
    return _storage[id];
  }

  @override
  Future<void> saveLog(DiveLog log) async {
    _storage[log.id] = log;
  }

  @override
  Future<void> deleteLog(String id) async {
    _storage.remove(id);
  }
}
