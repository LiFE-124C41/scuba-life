import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/interface/views/widgets/schedule_detail_sheet.dart';
import 'package:scuba_life/features/weather/domain/entities/marine_weather.dart';
import 'package:scuba_life/features/weather/domain/repositories/marine_weather_repository.dart';
import 'package:scuba_life/features/weather/interface/controllers/weather_controller.dart';

class MockTestWeatherRepository implements MarineWeatherRepository {
  @override
  Future<MarineWeather?> getForecastForLocation({
    required double latitude,
    required double longitude,
    required DateTime targetDate,
    String? spotName,
  }) async {
    return MarineWeather(
      spotName: spotName ?? 'テストポイント',
      forecastTime: targetDate,
      weatherDescription: '晴れ',
      airTemperatureCelsius: 24.5,
      waterTemperatureCelsius: 22.0,
      waveHeightMeter: 0.6,
      windDirection: '南東',
      windSpeedMeterPerSec: 3.2,
      estimatedVisibilityMeter: 18.0,
      tideType: TideType.spring,
    );
  }

  @override
  Future<MarineWeather> getWeatherBySpot(String spotName) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MarineWeather>> getPopularSpotWeathers() async {
    return [];
  }
}

void main() {
  testWidgets('ScheduleDetailSheet: 緯度経度がある場合、予定日の海況予報が表示されること',
      (WidgetTester tester) async {
    // Arrange
    final testSchedule = DiveSchedule(
      id: 'test-1',
      title: '伊豆海洋公園 ファンダイブ',
      eventDate: DateTime(2026, 10, 2),
      destination: '伊豆海洋公園',
      latitude: 34.8906,
      longitude: 139.1361,
      diveShop: 'テストショップ',
      plannedDivesCount: 2,
    );

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ScheduleDetailSheet(
              schedule: testSchedule,
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('予定日の海況・気象予報'), findsOneWidget);
    expect(find.text('潜水コンディション: 潜水良好'), findsOneWidget);
    expect(find.textContaining('晴れ'), findsWidgets);
    expect(find.text('22.0℃'), findsOneWidget); // 予想水温
    expect(find.text('0.6 m'), findsOneWidget); // 波高
    expect(find.text('約18 m'), findsOneWidget); // 予想透明度
    expect(find.text('大潮'), findsOneWidget); // 潮回り
    expect(find.text('提供: Open-Meteo Marine API'), findsOneWidget);
  });

  testWidgets('ScheduleDetailSheet: 緯度経度が未設定の場合、位置情報未設定メッセージが表示されること',
      (WidgetTester tester) async {
    // Arrange
    final noCoordSchedule = DiveSchedule(
      id: 'test-no-coord',
      title: 'ビーチダイビング',
      eventDate: DateTime(2026, 10, 2),
      destination: '未知のポイント',
      latitude: null,
      longitude: null,
      diveShop: 'テストショップ',
      plannedDivesCount: 1,
    );

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ScheduleDetailSheet(
              schedule: noCoordSchedule,
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('ダイビングポイントの緯度・経度が設定されていないため、海況予報を取得できません。'),
      findsOneWidget,
    );
  });
}
