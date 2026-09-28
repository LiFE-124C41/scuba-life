import '../../../core/usecase/usecase.dart';
import '../domain/entities/marine_weather.dart';
import '../domain/repositories/marine_weather_repository.dart';

/// 予定情報に基づく海況予報取得パラメータ
class GetMarineWeatherForScheduleParams {
  final double latitude;
  final double longitude;
  final DateTime targetDate;
  final String? spotName;

  const GetMarineWeatherForScheduleParams({
    required this.latitude,
    required this.longitude,
    required this.targetDate,
    this.spotName,
  });
}

/// 予定日の海況・気象予報を取得するユースケース
class GetMarineWeatherForSchedule
    implements UseCase<MarineWeather?, GetMarineWeatherForScheduleParams> {
  final MarineWeatherRepository repository;

  GetMarineWeatherForSchedule(this.repository);

  @override
  Future<MarineWeather?> call(GetMarineWeatherForScheduleParams params) async {
    return await repository.getForecastForLocation(
      latitude: params.latitude,
      longitude: params.longitude,
      targetDate: params.targetDate,
      spotName: params.spotName,
    );
  }
}
