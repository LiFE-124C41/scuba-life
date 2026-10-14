import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../../../../features/dive_spot/domain/entities/dive_spot.dart';
import '../domain/entities/app_remote_config.dart';
import '../domain/repositories/remote_config_repository.dart';

/// Firebase Remote Config を利用した RemoteConfigRepository の具象実装
class FirebaseRemoteConfigRepository implements RemoteConfigRepository {
  final FirebaseRemoteConfig? remoteConfig;
  AppRemoteConfig _currentConfig = const AppRemoteConfig();
  bool _isInitialized = false;
  bool _useFallback = false;

  FirebaseRemoteConfigRepository({
    this.remoteConfig,
  });

  FirebaseRemoteConfig get _instance =>
      remoteConfig ?? FirebaseRemoteConfig.instance;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (Firebase.apps.isEmpty) {
      _useFallback = true;
      _isInitialized = true;
      return;
    }

    try {
      await _instance.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 1),
        ),
      );

      // デフォルト値の登録
      await _instance.setDefaults(const {
        'preset_dive_spots_version': 1,
        'dynamic_dive_spots_json': '[]',
        'maintenance_banner_enabled': false,
        'maintenance_banner_message': '',
      });

      _isInitialized = true;
      _currentConfig = _parseConfig();
    } catch (e) {
      debugPrint('FirebaseRemoteConfig initialize error (using fallback): $e');
      _useFallback = true;
      _isInitialized = true;
    }
  }

  @override
  Future<AppRemoteConfig> fetchAndActivate() async {
    await initialize();

    if (_useFallback) {
      return _currentConfig;
    }

    try {
      await _instance.fetchAndActivate();
      _currentConfig = _parseConfig();
    } catch (e) {
      debugPrint('FirebaseRemoteConfig fetchAndActivate error: $e');
    }

    return _currentConfig;
  }

  @override
  AppRemoteConfig getCurrentConfig() {
    return _currentConfig;
  }

  AppRemoteConfig _parseConfig() {
    if (_useFallback) return _currentConfig;

    try {
      final version = _instance.getInt('preset_dive_spots_version');
      final bannerEnabled = _instance.getBool('maintenance_banner_enabled');
      final bannerMessage = _instance.getString('maintenance_banner_message');
      final dynamicSpotsJson = _instance.getString('dynamic_dive_spots_json');

      final dynamicSpots = _parseSpotsJson(dynamicSpotsJson);

      return AppRemoteConfig(
        presetDiveSpotsVersion: version > 0 ? version : 1,
        dynamicDiveSpots: dynamicSpots,
        maintenanceBannerEnabled: bannerEnabled,
        maintenanceBannerMessage: bannerMessage,
      );
    } catch (e) {
      debugPrint('Error parsing remote config: $e');
      return _currentConfig;
    }
  }

  /// JSON文字列から DiveSpot のリストを安全にパース
  static List<DiveSpot> _parseSpotsJson(String jsonStr) {
    if (jsonStr.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return const [];

      final spots = <DiveSpot>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            final spot = DiveSpot(
              id: item['id'] as String? ?? 'spot-${spots.length + 1}',
              name: item['name'] as String? ?? '',
              area: item['area'] as String? ?? '',
              latitude: (item['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (item['longitude'] as num?)?.toDouble() ?? 0.0,
              description: item['description'] as String? ?? '',
              isFavorite: item['isFavorite'] as bool? ?? false,
            );
            spots.add(spot);
          } catch (_) {
            // 単一スポットのバリデーションエラーはスキップ
          }
        }
      }
      return spots;
    } catch (e) {
      debugPrint('Failed to parse dynamic_dive_spots_json: $e');
      return const [];
    }
  }
}
