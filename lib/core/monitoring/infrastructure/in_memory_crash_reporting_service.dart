import '../domain/crash_reporting_service.dart';

/// テストおよびオフライン・未初期化時用のクラッシュ報告インメモリ実装
class InMemoryCrashReportingService implements CrashReportingService {
  String? currentUserId;
  final Map<String, Object> customKeys = {};
  final List<String> logs = [];
  final List<RecordedCrashError> recordedErrors = [];

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    recordedErrors.add(
      RecordedCrashError(
        exception: exception,
        stackTrace: stack,
        reason: reason,
        information: information.toList(),
        fatal: fatal,
      ),
    );
  }

  @override
  Future<void> setUserId(String userId) async {
    currentUserId = userId;
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }

  @override
  Future<void> setOfflineMode(bool isOffline) async {
    await setCustomKey('is_offline', isOffline);
  }

  @override
  Future<void> setCertificationInfo({String? org, String? level}) async {
    if (org != null) await setCustomKey('c_card_org', org);
    if (level != null) await setCustomKey('c_card_level', level);
  }

  void clear() {
    recordedErrors.clear();
    logs.clear();
    customKeys.clear();
    currentUserId = null;
  }
}

/// 記録されたエラーのレコード
class RecordedCrashError {
  final dynamic exception;
  final StackTrace? stackTrace;
  final dynamic reason;
  final List<Object> information;
  final bool fatal;
  final DateTime timestamp;

  RecordedCrashError({
    required this.exception,
    this.stackTrace,
    this.reason,
    required this.information,
    required this.fatal,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'RecordedCrashError(exception: $exception, fatal: $fatal, reason: $reason)';
}
