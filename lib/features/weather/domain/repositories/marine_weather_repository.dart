import '../entities/marine_weather.dart';

abstract class MarineWeatherRepository {
  Future<MarineWeather> getWeatherBySpot(String spotName);
  Future<List<MarineWeather>> getPopularSpotWeathers();
  Future<MarineWeather?> getForecastForLocation({
    required double latitude,
    required double longitude,
    required DateTime targetDate,
    String? spotName,
  });
}

