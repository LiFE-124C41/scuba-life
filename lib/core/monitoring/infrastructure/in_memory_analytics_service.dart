import '../domain/analytics_service.dart';

/// テストおよびオフライン・未初期化時用のアナリティクスインメモリ実装
class InMemoryAnalyticsService implements AnalyticsService {
  String? currentUserId;
  final Map<String, String?> userProperties = {};
  final List<AnalyticsEventRecord> recordedEvents = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    recordedEvents.add(
      AnalyticsEventRecord(
        name: name,
        parameters: parameters != null ? Map.from(parameters) : null,
      ),
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    currentUserId = userId;
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    userProperties[name] = value;
  }

  @override
  Future<void> logDiveLogCreated({
    required String spotName,
    required double maxDepth,
    required int durationMinutes,
    int? rating,
  }) async {
    await logEvent(
      name: 'dive_log_created',
      parameters: {
        'spot_name': spotName,
        'max_depth': maxDepth,
        'duration_minutes': durationMinutes,
        'rating': ?rating,
      },
    );
  }

  @override
  Future<void> logSacCalculated({
    required double sacRate,
    required double avgDepth,
    required int durationMinutes,
  }) async {
    await logEvent(
      name: 'sac_calculated',
      parameters: {
        'sac_rate': sacRate,
        'avg_depth': avgDepth,
        'duration_minutes': durationMinutes,
      },
    );
  }

  @override
  Future<void> logGearCreated({
    required String name,
    required String category,
  }) async {
    await logEvent(
      name: 'gear_created',
      parameters: {
        'gear_name': name,
        'category': category,
      },
    );
  }

  @override
  Future<void> logOverhaulCompleted({
    required String gearName,
    required String category,
    required int divesReset,
  }) async {
    await logEvent(
      name: 'overhaul_completed',
      parameters: {
        'gear_name': gearName,
        'category': category,
        'dives_reset': divesReset,
      },
    );
  }

  @override
  Future<void> logScreenView({required String screenName}) async {
    await logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
      },
    );
  }

  void clear() {
    recordedEvents.clear();
    userProperties.clear();
    currentUserId = null;
  }
}

/// 記録されたアナリティクスイベントのレコード
class AnalyticsEventRecord {
  final String name;
  final Map<String, Object>? parameters;
  final DateTime timestamp;

  AnalyticsEventRecord({
    required this.name,
    this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AnalyticsEventRecord(name: $name, parameters: $parameters)';
}
