/// 海況・海洋気象情報エンティティ
class MarineWeather {
  final String spotName; // ダイビングスポット名
  final DateTime forecastTime;
  final String weatherDescription; // 晴れ、曇り、雨など
  final double airTemperatureCelsius; // 気温 (°C)
  final double waterTemperatureCelsius; // 水温 (°C)
  final double waveHeightMeter; // 波高 (m)
  final String windDirection; // 風向 (例: 北東, 南西)
  final double windSpeedMeterPerSec; // 風速 (m/s)
  final double estimatedVisibilityMeter; // 予想透明度 (m)
  final TideType tideType; // 潮回り

  const MarineWeather({
    required this.spotName,
    required this.forecastTime,
    required this.weatherDescription,
    required this.airTemperatureCelsius,
    required this.waterTemperatureCelsius,
    required this.waveHeightMeter,
    required this.windDirection,
    required this.windSpeedMeterPerSec,
    required this.estimatedVisibilityMeter,
    required this.tideType,
  });

  /// 潜水可否の簡易判定（波高・風速に基づく）
  DivingConditionLevel get conditionLevel {
    if (waveHeightMeter >= 2.5 || windSpeedMeterPerSec >= 12.0) {
      return DivingConditionLevel.closed; // クローズの可能性大
    } else if (waveHeightMeter >= 1.5 || windSpeedMeterPerSec >= 8.0) {
      return DivingConditionLevel.caution; // 注意（上級者限定またはポイント限定）
    } else {
      return DivingConditionLevel.good; // 潜水良好
    }
  }
}

enum DivingConditionLevel {
  good('潜水良好'),
  caution('波・風あり（注意）'),
  closed('クローズの可能性高');

  final String label;
  const DivingConditionLevel(this.label);
}

enum TideType {
  spring('大潮'),
  middle('中潮'),
  neap('小潮'),
  long('長潮'),
  young('若潮');

  final String label;
  const TideType(this.label);
}
