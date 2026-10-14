import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/notification/infrastructure/flutter_local_notification_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // オフライン永続化キャッシュの明示的設定（洋上・ボート上など圏外での利用を最適化）
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Crashlytics グローバルエラーハンドラの設定
    if (!kIsWeb) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase initialization / Crashlytics setup error: $e');
  }

  // 通知リポジトリの初期化
  try {
    final notificationRepo = FlutterLocalNotificationRepository();
    await notificationRepo.initialize();
  } catch (e) {
    debugPrint('Notification setup error: $e');
  }

  runApp(
    const ProviderScope(
      child: ScubaLifeApp(),
    ),
  );
}

