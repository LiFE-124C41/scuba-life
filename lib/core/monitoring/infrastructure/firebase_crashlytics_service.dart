import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../domain/crash_reporting_service.dart';

/// Firebase Crashlytics を用いた本番用実装
class FirebaseCrashlyticsService implements CrashReportingService {
  final FirebaseCrashlytics? _crashlytics;

  FirebaseCrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? (kIsWeb ? null : FirebaseCrashlytics.instance);

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (kIsWeb || _crashlytics == null) {
      debugPrint('[CrashReporting (Web/Stub)] $exception');
      if (stack != null) debugPrint('$stack');
      return;
    }
    try {
      await _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('FirebaseCrashlytics recordError error: $e');
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    if (kIsWeb || _crashlytics == null) return;
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('FirebaseCrashlytics setUserIdentifier error: $e');
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    if (kIsWeb || _crashlytics == null) return;
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('FirebaseCrashlytics setCustomKey error: $e');
    }
  }

  @override
  Future<void> log(String message) async {
    if (kIsWeb || _crashlytics == null) {
      debugPrint('[CrashReporting log] $message');
      return;
    }
    try {
      await _crashlytics.log(message);
    } catch (e) {
      debugPrint('FirebaseCrashlytics log error: $e');
    }
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
}
