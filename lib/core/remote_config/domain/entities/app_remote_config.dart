import '../../../../features/dive_spot/domain/entities/dive_spot.dart';

/// Firebase Remote Config で配信される動的パラメータのエンティティ (Pure Dart)
class AppRemoteConfig {
  /// プリセットダイビングスポットマスタのバージョン
  final int presetDiveSpotsVersion;

  /// アプリ更新なしで動的に追加・更新されたダイビングスポット一覧
  final List<DiveSpot> dynamicDiveSpots;

  /// 緊急メンテナンス・障害バナー表示フラグ
  final bool maintenanceBannerEnabled;

  /// 緊急メンテナンス・障害バナーの文言
  final String maintenanceBannerMessage;

  const AppRemoteConfig({
    this.presetDiveSpotsVersion = 1,
    this.dynamicDiveSpots = const [],
    this.maintenanceBannerEnabled = false,
    this.maintenanceBannerMessage = '',
  });

  AppRemoteConfig copyWith({
    int? presetDiveSpotsVersion,
    List<DiveSpot>? dynamicDiveSpots,
    bool? maintenanceBannerEnabled,
    String? maintenanceBannerMessage,
  }) {
    return AppRemoteConfig(
      presetDiveSpotsVersion:
          presetDiveSpotsVersion ?? this.presetDiveSpotsVersion,
      dynamicDiveSpots: dynamicDiveSpots ?? this.dynamicDiveSpots,
      maintenanceBannerEnabled:
          maintenanceBannerEnabled ?? this.maintenanceBannerEnabled,
      maintenanceBannerMessage:
          maintenanceBannerMessage ?? this.maintenanceBannerMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppRemoteConfig &&
          runtimeType == other.runtimeType &&
          presetDiveSpotsVersion == other.presetDiveSpotsVersion &&
          maintenanceBannerEnabled == other.maintenanceBannerEnabled &&
          maintenanceBannerMessage == other.maintenanceBannerMessage &&
          _listEquals(dynamicDiveSpots, other.dynamicDiveSpots);

  @override
  int get hashCode =>
      presetDiveSpotsVersion.hashCode ^
      dynamicDiveSpots.length.hashCode ^
      maintenanceBannerEnabled.hashCode ^
      maintenanceBannerMessage.hashCode;

  static bool _listEquals(List<DiveSpot> a, List<DiveSpot> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
