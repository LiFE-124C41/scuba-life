import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check の初期化・有効化サービス
class AppCheckService {
  static bool _isActivated = false;

  /// App Check のアクティベーションを実行
  ///
  /// Android: Play Integrity（デバッグ時は Debug Provider）
  /// iOS / macOS: DeviceCheck（デバッグ時は Debug Provider）
  /// Web: デバッグ時はスキップまたはテストプロバイダー
  static Future<void> initialize({FirebaseAppCheck? appCheck}) async {
    if (_isActivated) return;

    try {
      if (Firebase.apps.isEmpty || kIsWeb) {
        return;
      }

      final instance = appCheck ?? FirebaseAppCheck.instance;

      // ignore: deprecated_member_use
      await instance.activate(
        // ignore: deprecated_member_use
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );

      _isActivated = true;
      debugPrint('Firebase App Check successfully activated (DebugMode: $kDebugMode).');
    } catch (e) {
      debugPrint('Firebase App Check activation failed (non-fatal): $e');
    }
  }
}
