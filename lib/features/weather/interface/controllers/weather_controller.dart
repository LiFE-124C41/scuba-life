import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/marine_weather.dart';
import '../../domain/repositories/marine_weather_repository.dart';
import '../../infrastructure/datasources/open_meteo_marine_remote_data_source.dart';
import '../../infrastructure/repositories/open_meteo_marine_weather_repository.dart';
import '../../usecase/get_marine_weather.dart';
import '../../usecase/get_marine_weather_for_schedule.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../schedule/domain/entities/dive_schedule.dart';

final openMeteoMarineRemoteDataSourceProvider =
    Provider<OpenMeteoMarineRemoteDataSource>((ref) {
  return OpenMeteoMarineRemoteDataSource();
});

final marineWeatherRepositoryProvider = Provider<MarineWeatherRepository>((ref) {
  final remoteDataSource = ref.watch(openMeteoMarineRemoteDataSourceProvider);
  return OpenMeteoMarineWeatherRepository(remoteDataSource: remoteDataSource);
});

final getPopularSpotWeathersUseCaseProvider =
    Provider<GetPopularSpotWeathers>((ref) {
  final repo = ref.watch(marineWeatherRepositoryProvider);
  return GetPopularSpotWeathers(repo);
});

final popularSpotWeathersProvider =
    FutureProvider<List<MarineWeather>>((ref) async {
  final useCase = ref.watch(getPopularSpotWeathersUseCaseProvider);
  return await useCase(const NoParams());
});

final getMarineWeatherForScheduleUseCaseProvider =
    Provider<GetMarineWeatherForSchedule>((ref) {
  final repo = ref.watch(marineWeatherRepositoryProvider);
  return GetMarineWeatherForSchedule(repo);
});

/// 予定情報（DiveSchedule）に対する海況・気象予報プロバイダ
final scheduleMarineWeatherProvider =
    FutureProvider.family<MarineWeather?, DiveSchedule>((ref, schedule) async {
  if (schedule.latitude == null || schedule.longitude == null) {
    return null;
  }
  final useCase = ref.watch(getMarineWeatherForScheduleUseCaseProvider);
  return await useCase(
    GetMarineWeatherForScheduleParams(
      latitude: schedule.latitude!,
      longitude: schedule.longitude!,
      targetDate: schedule.eventDate,
      spotName: schedule.destination,
    ),
  );
});
