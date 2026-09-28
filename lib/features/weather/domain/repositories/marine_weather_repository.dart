import '../entities/marine_weather.dart';

abstract class MarineWeatherRepository {
  Future<MarineWeather> getWeatherBySpot(String spotName);
  Future<List<MarineWeather>> getPopularSpotWeathers();
}
