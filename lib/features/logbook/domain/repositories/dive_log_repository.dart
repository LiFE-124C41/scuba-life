import '../entities/dive_log.dart';

/// ログブック永続化のインターフェース
///
/// 具象実装（SQLite, Hive, Firestore等）はinfrastructure層で提供し、
/// ドメイン層およびユースケース層はこの抽象にのみ依存する。
abstract class DiveLogRepository {
  Future<List<DiveLog>> getAllLogs();
  Future<DiveLog?> getLogById(String id);
  Future<void> saveLog(DiveLog log);
  Future<void> deleteLog(String id);
}
