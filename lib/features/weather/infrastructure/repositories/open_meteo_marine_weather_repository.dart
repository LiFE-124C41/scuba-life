import '../../domain/entities/marine_weather.dart';
import '../../domain/repositories/marine_weather_repository.dart';
import '../datasources/open_meteo_marine_remote_data_source.dart';

/// Open-Meteo Marine APIを利用した海洋気象リポジトリ実装
class OpenMeteoMarineWeatherRepository implements MarineWeatherRepository {
  final OpenMeteoMarineRemoteDataSource remoteDataSource;

  OpenMeteoMarineWeatherRepository({
    required this.remoteDataSource,
  });

  @override
  Future<MarineWeather?> getForecastForLocation({
    required double latitude,
    required double longitude,
    required DateTime targetDate,
    String? spotName,
  }) async {
    final dto = await remoteDataSource.fetchForecast(
      latitude: latitude,
      longitude: longitude,
      targetDate: targetDate,
    );

    if (dto == null) {
      return null;
    }

    // 波高と風速に基づく透明度推定ロジック
    final visibility = _estimateVisibility(
      waveHeight: dto.waveHeightMeter,
      windSpeed: dto.windSpeedMeterPerSec,
    );

    // 月齢に基づく簡易潮回り推定
    final tide = _estimateTide(targetDate);

    return MarineWeather(
      spotName: spotName ?? '指定ポイント (${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)})',
      forecastTime: dto.date,
      weatherDescription: dto.weatherDescription,
      airTemperatureCelsius: dto.airTemperatureCelsius,
      waterTemperatureCelsius: dto.waterTemperatureCelsius,
      waveHeightMeter: dto.waveHeightMeter,
      windDirection: dto.windDirection,
      windSpeedMeterPerSec: dto.windSpeedMeterPerSec,
      estimatedVisibilityMeter: visibility,
      tideType: tide,
    );
  }

  @override
  Future<MarineWeather> getWeatherBySpot(String spotName) async {
    // スポット名から代表緯度経度を取得（デフォルトは大瀬崎）
    final spotCoords = _popularSpotCoordinates[spotName] ??
        const _Coordinates(35.0308, 138.7903);
    final forecast = await getForecastForLocation(
      latitude: spotCoords.latitude,
      longitude: spotCoords.longitude,
      targetDate: DateTime.now(),
      spotName: spotName,
    );

    return forecast ??
        MarineWeather(
          spotName: spotName,
          forecastTime: DateTime.now(),
          weatherDescription: '晴れ',
          airTemperatureCelsius: 22.0,
          waterTemperatureCelsius: 20.0,
          waveHeightMeter: 0.8,
          windDirection: '南東',
          windSpeedMeterPerSec: 3.0,
          estimatedVisibilityMeter: 15.0,
          tideType: TideType.middle,
        );
  }

  @override
  Future<List<MarineWeather>> getPopularSpotWeathers() async {
    final list = <MarineWeather>[];
    for (final entry in _popularSpotCoordinates.entries) {
      final weather = await getForecastForLocation(
        latitude: entry.value.latitude,
        longitude: entry.value.longitude,
        targetDate: DateTime.now(),
        spotName: entry.key,
      );
      if (weather != null) {
        list.add(weather);
      }
    }
    return list;
  }

  /// 波高と風速から推定透明度（m）を算出
  static double _estimateVisibility({
    required double waveHeight,
    required double windSpeed,
  }) {
    if (waveHeight < 0.6 && windSpeed < 4.0) {
      return 20.0;
    } else if (waveHeight < 1.0 && windSpeed < 6.0) {
      return 15.0;
    } else if (waveHeight < 1.5 && windSpeed < 9.0) {
      return 10.0;
    } else if (waveHeight < 2.0) {
      return 6.0;
    } else {
      return 4.0;
    }
  }

  /// 日付から月齢を計算して潮回りを簡易判定
  static TideType _estimateTide(DateTime date) {
    // 基準新月日（2000年1月6日）からの日数
    final baseNewMoon = DateTime(2000, 1, 6);
    final days = date.difference(baseNewMoon).inDays;
    final synodicMonth = 29.53058867; // 朔望月
    final moonAge = days % synodicMonth;

    if ((moonAge >= 0 && moonAge < 2.5) ||
        (moonAge >= 14 && moonAge < 17.5) ||
        moonAge >= 28.5) {
      return TideType.spring; // 大潮
    } else if ((moonAge >= 2.5 && moonAge < 6.5) ||
        (moonAge >= 11 && moonAge < 14) ||
        (moonAge >= 17.5 && moonAge < 21.5) ||
        (moonAge >= 25.5 && moonAge < 28.5)) {
      return TideType.middle; // 中潮
    } else if ((moonAge >= 6.5 && moonAge < 9.5) ||
        (moonAge >= 21.5 && moonAge < 24.5)) {
      return TideType.neap; // 小潮
    } else if ((moonAge >= 9.5 && moonAge < 10.5) ||
        (moonAge >= 24.5 && moonAge < 25.5)) {
      return TideType.long; // 長潮
    } else {
      return TideType.young; // 若潮
    }
  }

  static const Map<String, _Coordinates> _popularSpotCoordinates = {
    '大瀬崎 (静岡)': _Coordinates(35.0308, 138.7903),
    '神子元島 (静岡)': _Coordinates(34.5828, 138.9328),
    '慶良間・座間味 (沖縄)': _Coordinates(26.2083, 127.2889),
  };
}

class _Coordinates {
  final double latitude;
  final double longitude;
  const _Coordinates(this.latitude, this.longitude);
}
