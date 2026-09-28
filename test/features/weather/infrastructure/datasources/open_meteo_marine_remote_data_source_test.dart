import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scuba_life/features/weather/infrastructure/datasources/open_meteo_marine_remote_data_source.dart';

void main() {
  group('OpenMeteoMarineRemoteDataSource Tests', () {
    test('正常系: Open-MeteoのMarine及びForecastレスポンスが正常にパースされること', () async {
      // Arrange: モックHTTPクライアントでOpen-Meteoのレスポンスを模擬
      final targetDate = DateTime(2026, 9, 29);
      final dateStr = '2026-09-29';

      final mockClient = MockClient((request) async {
        if (request.url.host == 'marine-api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'daily': {
                'time': [dateStr],
                'wave_height_max': [0.75],
                'wave_direction_dominant': [135],
              },
              'hourly': {
                'time': ['${dateStr}T12:00'],
                'sea_surface_temperature': [22.4],
              },
            }),
            200,
          );
        } else if (request.url.host == 'api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'daily': {
                'time': [dateStr],
                'weather_code': [1], // 晴れ
                'temperature_2m_max': [25.0],
                'wind_speed_10m_max': [14.4], // 14.4 km/h = 4.0 m/s
                'wind_direction_10m_dominant': [90], // 東
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = OpenMeteoMarineRemoteDataSource(client: mockClient);

      // Act
      final result = await dataSource.fetchForecast(
        latitude: 35.0308,
        longitude: 138.7903,
        targetDate: targetDate,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.weatherDescription, '晴れ');
      expect(result.airTemperatureCelsius, 25.0);
      expect(result.waterTemperatureCelsius, 22.4);
      expect(result.waveHeightMeter, 0.75);
      expect(result.windSpeedMeterPerSec, 4.0);
      expect(result.windDirection, '東');
    });

    test('予報期間外: 該当する日付がAPIレスポンスに含まれない場合、nullを返すこと', () async {
      // Arrange
      final targetDate = DateTime(2026, 10, 20); // 予報外

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-09-29'],
              'wave_height_max': [0.8],
              'weather_code': [0],
              'temperature_2m_max': [20.0],
              'wind_speed_10m_max': [10.0],
              'wind_direction_10m_dominant': [0],
            },
          }),
          200,
        );
      });

      final dataSource = OpenMeteoMarineRemoteDataSource(client: mockClient);

      // Act
      final result = await dataSource.fetchForecast(
        latitude: 35.0,
        longitude: 138.0,
        targetDate: targetDate,
      );

      // Assert
      expect(result, isNull);
    });

    test('異常系: API呼び出しがエラーステータス（500等）の場合、例外がスローされること', () async {
      // Arrange
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final dataSource = OpenMeteoMarineRemoteDataSource(client: mockClient);

      // Act & Assert
      expect(
        () async => await dataSource.fetchForecast(
          latitude: 35.0,
          longitude: 138.0,
          targetDate: DateTime.now(),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
