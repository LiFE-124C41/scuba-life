import '../../domain/entities/marine_weather.dart';
import '../../domain/repositories/marine_weather_repository.dart';

class MockMarineWeatherRepository implements MarineWeatherRepository {
  @override
  Future<MarineWeather> getWeatherBySpot(String spotName) async {
    return MarineWeather(
      spotName: spotName,
      forecastTime: DateTime.now(),
      weatherDescription: '晴れ時々曇り',
      airTemperatureCelsius: 24.0,
      waterTemperatureCelsius: 21.5,
      waveHeightMeter: 0.8,
      windDirection: '北東',
      windSpeedMeterPerSec: 3.5,
      estimatedVisibilityMeter: 15.0,
      tideType: TideType.middle,
    );
  }

  @override
  Future<List<MarineWeather>> getPopularSpotWeathers() async {
    return [
      MarineWeather(
        spotName: '大瀬崎 (静岡)',
        forecastTime: DateTime.now(),
        weatherDescription: '晴れ',
        airTemperatureCelsius: 23.5,
        waterTemperatureCelsius: 20.0,
        waveHeightMeter: 0.5,
        windDirection: '東',
        windSpeedMeterPerSec: 2.0,
        estimatedVisibilityMeter: 12.0,
        tideType: TideType.middle,
      ),
      MarineWeather(
        spotName: '神子元島 (静岡)',
        forecastTime: DateTime.now(),
        weatherDescription: '曇り',
        airTemperatureCelsius: 22.0,
        waterTemperatureCelsius: 21.0,
        waveHeightMeter: 1.8,
        windDirection: '南西',
        windSpeedMeterPerSec: 7.5,
        estimatedVisibilityMeter: 18.0,
        tideType: TideType.middle,
      ),
      MarineWeather(
        spotName: '慶良間・座間味 (沖縄)',
        forecastTime: DateTime.now(),
        weatherDescription: '快晴',
        airTemperatureCelsius: 28.0,
        waterTemperatureCelsius: 26.5,
        waveHeightMeter: 1.0,
        windDirection: '南',
        windSpeedMeterPerSec: 4.0,
        estimatedVisibilityMeter: 30.0,
        tideType: TideType.spring,
      ),
    ];
  }
}
