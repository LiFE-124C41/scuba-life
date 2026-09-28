import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/weather/domain/entities/marine_weather.dart';

void main() {
  group('MarineWeather Domain Entity Tests', () {
    test('波高・風速が穏やかな場合、潜水コンディションが「潜水良好 (good)」と判定されること', () {
      // Arrange
      final weather = MarineWeather(
        spotName: '大瀬崎 湾内',
        forecastTime: DateTime.now(),
        weatherDescription: '晴れ',
        airTemperatureCelsius: 24.0,
        waterTemperatureCelsius: 21.0,
        waveHeightMeter: 0.5,
        windDirection: '北東',
        windSpeedMeterPerSec: 3.0,
        estimatedVisibilityMeter: 15.0,
        tideType: TideType.middle,
      );

      // Act
      final level = weather.conditionLevel;

      // Assert
      expect(level, DivingConditionLevel.good);
      expect(level.label, '潜水良好');
    });

    test('波高1.5m以上または風速8.0m/s以上の場合、「注意 (caution)」と判定されること', () {
      // Arrange (波高注意)
      final weatherWaveCaution = MarineWeather(
        spotName: '伊豆海洋公園',
        forecastTime: DateTime.now(),
        weatherDescription: '曇り',
        airTemperatureCelsius: 22.0,
        waterTemperatureCelsius: 20.0,
        waveHeightMeter: 1.6,
        windDirection: '東',
        windSpeedMeterPerSec: 4.0,
        estimatedVisibilityMeter: 10.0,
        tideType: TideType.middle,
      );

      // Arrange (風速注意)
      final weatherWindCaution = MarineWeather(
        spotName: '伊豆海洋公園',
        forecastTime: DateTime.now(),
        weatherDescription: '曇り',
        airTemperatureCelsius: 22.0,
        waterTemperatureCelsius: 20.0,
        waveHeightMeter: 0.8,
        windDirection: '南西',
        windSpeedMeterPerSec: 9.0,
        estimatedVisibilityMeter: 10.0,
        tideType: TideType.middle,
      );

      // Act & Assert
      expect(weatherWaveCaution.conditionLevel, DivingConditionLevel.caution);
      expect(weatherWindCaution.conditionLevel, DivingConditionLevel.caution);
    });

    test('波高2.5m以上または風速12.0m/s以上の場合、「クローズ可能性高 (closed)」と判定されること', () {
      // Arrange
      final weatherClosed = MarineWeather(
        spotName: '神子元島',
        forecastTime: DateTime.now(),
        weatherDescription: '雨',
        airTemperatureCelsius: 19.0,
        waterTemperatureCelsius: 20.0,
        waveHeightMeter: 2.8,
        windDirection: '南西',
        windSpeedMeterPerSec: 14.0,
        estimatedVisibilityMeter: 5.0,
        tideType: TideType.spring,
      );

      // Act
      final level = weatherClosed.conditionLevel;

      // Assert
      expect(level, DivingConditionLevel.closed);
      expect(level.label, 'クローズの可能性高');
    });
  });
}
