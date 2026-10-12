import 'dart:convert';
import 'package:http/http.dart' as http;

/// Open-Meteo APIからの生データモデル（DTO）
class OpenMeteoForecastDto {
  final DateTime date;
  final String weatherDescription;
  final double airTemperatureCelsius;
  final double waterTemperatureCelsius;
  final double waveHeightMeter;
  final String windDirection;
  final double windSpeedMeterPerSec;

  const OpenMeteoForecastDto({
    required this.date,
    required this.weatherDescription,
    required this.airTemperatureCelsius,
    required this.waterTemperatureCelsius,
    required this.waveHeightMeter,
    required this.windDirection,
    required this.windSpeedMeterPerSec,
  });
}

/// Open-Meteo Marine & Forecast APIと通信するRemoteDataSource
class OpenMeteoMarineRemoteDataSource {
  final http.Client _client;

  OpenMeteoMarineRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  /// 指定した緯度・経度および対象日の海況・気象データを取得
  ///
  /// 予報期間（通常は当日含め8日間）を超える場合は null を返す
  Future<OpenMeteoForecastDto?> fetchForecast({
    required double latitude,
    required double longitude,
    required DateTime targetDate,
  }) async {
    final dateStr =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    final marineUri = Uri.parse(
      'https://marine-api.open-meteo.com/v1/marine'
      '?latitude=$latitude&longitude=$longitude'
      '&daily=wave_height_max,wave_direction_dominant'
      '&hourly=sea_surface_temperature'
      '&timezone=auto&forecast_days=8',
    );

    final forecastUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&daily=weather_code,temperature_2m_max,wind_speed_10m_max,wind_direction_10m_dominant'
      '&timezone=auto&forecast_days=8',
    );

    final marineResponse = await _client.get(marineUri);
    final forecastResponse = await _client.get(forecastUri);

    if (marineResponse.statusCode != 200 || forecastResponse.statusCode != 200) {
      throw Exception('Open-Meteo APIの呼び出しに失敗しました。Status: ${marineResponse.statusCode}, ${forecastResponse.statusCode}');
    }

    final marineJson = jsonDecode(marineResponse.body) as Map<String, dynamic>;
    final forecastJson = jsonDecode(forecastResponse.body) as Map<String, dynamic>;

    final marineDaily = marineJson['daily'] as Map<String, dynamic>?;
    final forecastDaily = forecastJson['daily'] as Map<String, dynamic>?;
    final marineHourly = marineJson['hourly'] as Map<String, dynamic>?;

    if (marineDaily == null || forecastDaily == null) {
      return null;
    }

    final dateList = List<String>.from(forecastDaily['time'] ?? []);
    final targetIndex = dateList.indexOf(dateStr);
    if (targetIndex == -1) {
      // 予報範囲外（8日以上先、または過去）
      return null;
    }

    // 気象情報
    final weatherCodes = List<dynamic>.from(forecastDaily['weather_code'] ?? []);
    final weatherCode = targetIndex < weatherCodes.length ? (weatherCodes[targetIndex] as num).toInt() : 0;
    final weatherDesc = _weatherCodeToJapanese(weatherCode);

    final maxTemps = List<dynamic>.from(forecastDaily['temperature_2m_max'] ?? []);
    final airTemp = targetIndex < maxTemps.length ? (maxTemps[targetIndex] as num).toDouble() : 20.0;

    final windSpeeds = List<dynamic>.from(forecastDaily['wind_speed_10m_max'] ?? []);
    // Open-Meteoのデフォルト風速はkm/h -> m/s に換算 (/ 3.6)
    final windSpeedKmh = targetIndex < windSpeeds.length ? (windSpeeds[targetIndex] as num).toDouble() : 10.0;
    final windSpeedMs = double.parse((windSpeedKmh / 3.6).toStringAsFixed(1));

    final windDirs = List<dynamic>.from(forecastDaily['wind_direction_10m_dominant'] ?? []);
    final windDirDeg = targetIndex < windDirs.length ? (windDirs[targetIndex] as num).toDouble() : 0.0;
    final windDirStr = _degreesToDirection(windDirDeg);

    // 海況情報
    final waveHeights = List<dynamic>.from(marineDaily['wave_height_max'] ?? []);
    final waveHeight = targetIndex < waveHeights.length && waveHeights[targetIndex] != null
        ? (waveHeights[targetIndex] as num).toDouble()
        : 0.8;

    // 海面水温（hourly から該当日の正午 12:00 の値を抽出、なければ代表値）
    double waterTemp = 21.0;
    if (marineHourly != null) {
      final hourlyTimes = List<String>.from(marineHourly['time'] ?? []);
      final hourlySst = List<dynamic>.from(marineHourly['sea_surface_temperature'] ?? []);
      final targetNoonTime = '${dateStr}T12:00';
      final noonIndex = hourlyTimes.indexOf(targetNoonTime);
      if (noonIndex != -1 && noonIndex < hourlySst.length && hourlySst[noonIndex] != null) {
        waterTemp = (hourlySst[noonIndex] as num).toDouble();
      } else {
        // nullでなければ先頭有効値
        final validSst = hourlySst.where((v) => v != null).toList();
        if (validSst.isNotEmpty) {
          waterTemp = (validSst.first as num).toDouble();
        }
      }
    }

    return OpenMeteoForecastDto(
      date: targetDate,
      weatherDescription: weatherDesc,
      airTemperatureCelsius: airTemp,
      waterTemperatureCelsius: waterTemp,
      waveHeightMeter: waveHeight,
      windDirection: windDirStr,
      windSpeedMeterPerSec: windSpeedMs,
    );
  }

  /// WMO気象コードを日本語の天気に変換
  static String _weatherCodeToJapanese(int code) {
    switch (code) {
      case 0:
        return '快晴';
      case 1:
        return '晴れ';
      case 2:
        return '時々曇り';
      case 3:
        return '曇り';
      case 45:
      case 48:
        return '霧';
      case 51:
      case 53:
      case 55:
        return '霧雨';
      case 61:
      case 63:
      case 65:
        return '雨';
      case 71:
      case 73:
      case 75:
        return '雪';
      case 80:
      case 81:
      case 82:
        return 'にわか雨';
      case 95:
      case 96:
      case 99:
        return '雷雨';
      default:
        return '晴れ時々曇り';
    }
  }

  /// 方位角（度数）を16方位の文字列に変換
  static String _degreesToDirection(double degrees) {
    final directions = [
      '北', '北北東', '北東', '東北東',
      '東', '東南東', '南東', '南南東',
      '南', '南南西', '南西', '西南西',
      '西', '西北西', '北西', '北北西',
    ];
    final normalized = (degrees % 360 + 360) % 360;
    final index = ((normalized + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}
