import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../domain/analytics_service.dart';

/// Firebase Analytics を用いた本番用実装
class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('FirebaseAnalytics logEvent error: $e');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('FirebaseAnalytics setUserId error: $e');
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('FirebaseAnalytics setUserProperty error: $e');
    }
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
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('FirebaseAnalytics logScreenView error: $e');
    }
  }
}
