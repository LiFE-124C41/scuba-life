import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/weather/domain/entities/marine_weather.dart';
import 'package:scuba_life/features/weather/domain/repositories/marine_weather_repository.dart';
import 'package:scuba_life/features/weather/usecase/get_marine_weather_for_schedule.dart';

/// テスト用のモックリポジトリ
class FakeMarineWeatherRepository implements MarineWeatherRepository {
  MarineWeather? returnWeather;
  double? capturedLatitude;
  double? capturedLongitude;
  DateTime? capturedDate;

  @override
  Future<MarineWeather?> getForecastForLocation({
    required double latitude,
    required double longitude,
    required DateTime targetDate,
    String? spotName,
  }) async {
    capturedLatitude = latitude;
    capturedLongitude = longitude;
    capturedDate = targetDate;
    return returnWeather;
  }

  @override
  Future<MarineWeather> getWeatherBySpot(String spotName) {
    throw UnimplementedError();
  }

  @override
  Future<List<MarineWeather>> getPopularSpotWeathers() {
    throw UnimplementedError();
  }
}

void main() {
  group('GetMarineWeatherForSchedule UseCase Tests', () {
    late FakeMarineWeatherRepository fakeRepository;
    late GetMarineWeatherForSchedule useCase;

    setUp(() {
      fakeRepository = FakeMarineWeatherRepository();
      useCase = GetMarineWeatherForSchedule(fakeRepository);
    });

    test('指定された緯度・経度・日付でリポジトリが呼び出され、海況情報が取得できること', () async {
      // Arrange
      final targetDate = DateTime(2026, 10, 5);
      final expectedWeather = MarineWeather(
        spotName: '伊豆海洋公園',
        forecastTime: targetDate,
        weatherDescription: '晴れ',
        airTemperatureCelsius: 22.0,
        waterTemperatureCelsius: 20.0,
        waveHeightMeter: 0.8,
        windDirection: '北東',
        windSpeedMeterPerSec: 3.5,
        estimatedVisibilityMeter: 15.0,
        tideType: TideType.middle,
      );
      fakeRepository.returnWeather = expectedWeather;

      final params = GetMarineWeatherForScheduleParams(
        latitude: 34.8906,
        longitude: 139.1361,
        targetDate: targetDate,
        spotName: '伊豆海洋公園',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(expectedWeather));
      expect(fakeRepository.capturedLatitude, 34.8906);
      expect(fakeRepository.capturedLongitude, 139.1361);
      expect(fakeRepository.capturedDate, targetDate);
    });

    test('予報範囲外などの理由でリポジトリがnullを返した場合、nullが返却されること', () async {
      // Arrange
      fakeRepository.returnWeather = null;
      final params = GetMarineWeatherForScheduleParams(
        latitude: 35.0,
        longitude: 138.0,
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, isNull);
    });
  });
}
