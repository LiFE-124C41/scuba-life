import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/marine_weather.dart';
import '../../domain/repositories/marine_weather_repository.dart';
import '../../infrastructure/repositories/mock_marine_weather_repository.dart';
import '../../usecase/get_marine_weather.dart';
import '../../../../core/usecase/usecase.dart';

final marineWeatherRepositoryProvider = Provider<MarineWeatherRepository>((ref) {
  return MockMarineWeatherRepository();
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
