import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/domain/entities/user_account.dart';
import '../../../features/auth/interface/controllers/user_profile_controller.dart';
import '../domain/analytics_service.dart';
import '../domain/crash_reporting_service.dart';
import '../infrastructure/firebase_analytics_service.dart';
import '../infrastructure/firebase_crashlytics_service.dart';
import '../infrastructure/in_memory_analytics_service.dart';
import '../infrastructure/in_memory_crash_reporting_service.dart';

/// Analytics サービスを提供する Provider
/// テスト環境等で容易に override 可能
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  try {
    return FirebaseAnalyticsService();
  } catch (_) {
    return InMemoryAnalyticsService();
  }
});

/// Crashlytics サービスを提供する Provider
/// テスト環境等で容易に override 可能
final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  try {
    return FirebaseCrashlyticsService();
  } catch (_) {
    return InMemoryCrashReportingService();
  }
});

/// 認証状態・ダイバープロファイルと監視サービス（Analytics / Crashlytics）を自動同期する Provider
final monitoringSyncProvider = Provider<void>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  final crashReporting = ref.watch(crashReportingServiceProvider);

  ref.listen<AsyncValue<UserAccount?>>(
    currentUserProfileProvider,
    (previous, next) {
      next.whenData((user) {
        if (user != null) {
          analytics.setUserId(user.id);
          crashReporting.setUserId(user.id);

          if (user.certificationOrg != null) {
            analytics.setUserProperty(
              name: 'certification_org',
              value: user.certificationOrg,
            );
          }
          if (user.certificationLevel != null) {
            analytics.setUserProperty(
              name: 'certification_level',
              value: user.certificationLevel,
            );
          }
          crashReporting.setCertificationInfo(
            org: user.certificationOrg,
            level: user.certificationLevel,
          );
        } else {
          analytics.setUserId(null);
        }
      });
    },
    fireImmediately: true,
  );
});
