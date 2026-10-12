import '../../../core/usecase/usecase.dart';
import '../domain/entities/marine_weather.dart';
import '../domain/repositories/marine_weather_repository.dart';

class GetPopularSpotWeathers implements UseCase<List<MarineWeather>, NoParams> {
  final MarineWeatherRepository _repository;

  GetPopularSpotWeathers(this._repository);

  @override
  Future<List<MarineWeather>> call(NoParams params) async {
    return await _repository.getPopularSpotWeathers();
  }
}
