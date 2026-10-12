import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/infrastructure/repositories/in_memory_gear_repository.dart';
import 'package:scuba_life/features/my_gear/interface/controllers/gear_controller.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/infrastructure/repositories/in_memory_dive_schedule_repository.dart';
import 'package:scuba_life/features/schedule/interface/controllers/schedule_controller.dart';
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

  testWidgets('ScheduleDetailSheet: 2376x968端末等（幅360px前後）でも海況グリッドがオーバーフローせずに描画できること',
      (WidgetTester tester) async {
    // Arrange: 2376x968 (縦向き: 論理幅 約368px, ここではより厳しい360x900で検証)
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    final testSchedule = DiveSchedule(
      id: 'test-responsiveness',
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

    // Assert: オーバーフロー例外が発生していないこと
    expect(tester.takeException(), isNull);
  });

  group('持ち物・機材チェックリスト', () {
    final sampleGears = [
      GearItem(
        id: 'gear-1',
        name: 'Apeks XTX200 レギュレーター',
        category: GearCategory.regulator,
        brand: 'Apeks',
        model: 'XTX200',
        purchaseDate: DateTime(2023, 1, 1),
      ),
      GearItem(
        id: 'gear-2',
        name: 'SUUNTO D5 ダイブコンピューター',
        category: GearCategory.diveComputer,
        brand: 'SUUNTO',
        model: 'D5',
        purchaseDate: DateTime(2023, 2, 1),
      ),
    ];

    testWidgets('機材一覧と初期チェック状態、進捗バッジが正しく表示されること', (WidgetTester tester) async {
      // Arrange
      final schedule = DiveSchedule(
        id: 'test-gear-1',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: DateTime(2026, 10, 2),
        destination: '伊豆海洋公園',
        diveShop: 'テストショップ',
        checkedGearIds: ['gear-1'], // gear-1 のみ初期チェック済み
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
            gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
            diveScheduleRepositoryProvider.overrideWithValue(
              InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('持ち物・機材チェックリスト'), findsOneWidget);
      expect(find.text('1 / 2 完了'), findsOneWidget);
      expect(find.text('全選択'), findsOneWidget);
      expect(find.text('Apeks XTX200 レギュレーター'), findsOneWidget);
      expect(find.text('SUUNTO D5 ダイブコンピューター'), findsOneWidget);

      // チェックボックスの確認 (gear-1 は true, gear-2 は false)
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes.length, 2);
      expect(checkboxes[0].value, isTrue);
      expect(checkboxes[1].value, isFalse);
    });

    testWidgets('機材の行をタップするとチェック状態がトグルされること', (WidgetTester tester) async {
      // Arrange
      final schedule = DiveSchedule(
        id: 'test-toggle-1',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: DateTime(2026, 10, 2),
        destination: '伊豆海洋公園',
        diveShop: 'テストショップ',
        checkedGearIds: ['gear-1'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
            gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
            diveScheduleRepositoryProvider.overrideWithValue(
              InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 未チェックの gear-2 (SUUNTO D5) をタップ
      await tester.tap(find.text('SUUNTO D5 ダイブコンピューター'));
      await tester.pumpAndSettle();

      // Assert: 両方チェックされ、バッジが「準備完了!」、ボタンが「全解除」になる
      expect(find.text('準備完了!'), findsOneWidget);
      expect(find.text('全解除'), findsOneWidget);
      final checkboxesAfterCheck = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxesAfterCheck[0].value, isTrue);
      expect(checkboxesAfterCheck[1].value, isTrue);

      // Act: 再度タップして解除
      await tester.tap(find.text('SUUNTO D5 ダイブコンピューター'));
      await tester.pumpAndSettle();

      // Assert: 1 / 2 完了に戻る
      expect(find.text('1 / 2 完了'), findsOneWidget);
      expect(find.text('全選択'), findsOneWidget);
    });

    testWidgets('全選択ボタンと全解除ボタンで一括操作ができること', (WidgetTester tester) async {
      // Arrange
      final schedule = DiveSchedule(
        id: 'test-bulk-1',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: DateTime(2026, 10, 2),
        destination: '伊豆海洋公園',
        diveShop: 'テストショップ',
        checkedGearIds: const [], // 初期状態は未チェック
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
            gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
            diveScheduleRepositoryProvider.overrideWithValue(
              InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 / 2 完了'), findsOneWidget);
      expect(find.text('全選択'), findsOneWidget);

      // Act: 全選択をタップ
      await tester.tap(find.text('全選択'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('準備完了!'), findsOneWidget);
      expect(find.text('全解除'), findsOneWidget);
      for (final cb in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
        expect(cb.value, isTrue);
      }

      // Act: 全解除をタップ
      await tester.tap(find.text('全解除'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('0 / 2 完了'), findsOneWidget);
      expect(find.text('全選択'), findsOneWidget);
      for (final cb in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
        expect(cb.value, isFalse);
      }
    });

    testWidgets('機材が未登録の場合、ガイダンスメッセージが表示されること', (WidgetTester tester) async {
      // Arrange: 機材が空
      final schedule = DiveSchedule(
        id: 'test-empty-gears',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: DateTime(2026, 10, 2),
        destination: '伊豆海洋公園',
        diveShop: 'テストショップ',
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
            gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: [])),
            diveScheduleRepositoryProvider.overrideWithValue(
              InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('持ち物・機材チェックリスト'), findsOneWidget);
      expect(
        find.text('機材管理でマイ機材を登録すると、ここに自動で持ち物チェックリストとして表示されます。'),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('全選択'), findsNothing);
    });

    testWidgets('targetGearIdsが指定されている場合、対象機材のみがチェックリストに表示され、分母が連動すること',
        (WidgetTester tester) async {
      // Arrange: sampleGears のうち gear-1 のみ持参対象、かつチェック済み
      final schedule = DiveSchedule(
        id: 'test-filtered-target',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: DateTime(2026, 10, 2),
        destination: '伊豆海洋公園',
        diveShop: 'テストショップ',
        targetGearIds: ['gear-1'], // gear-2 (SUUNTO D5) は除外
        checkedGearIds: ['gear-1'],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
            gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
            diveScheduleRepositoryProvider.overrideWithValue(
              InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: gear-1 のみ表示され、1件中1件で「準備完了!」となること
      expect(find.text('Apeks XTX200 レギュレーター'), findsOneWidget);
      expect(find.text('SUUNTO D5 ダイブコンピューター'), findsNothing);
      expect(find.text('準備完了!'), findsOneWidget);
      expect(find.text('機材変更中'), findsOneWidget);
    });

    testWidgets('持参機材が0件に設定されている場合、未選択ガイダンスが表示されること',
        (WidgetTester tester) async {
      // Arrange: 機材管理には機材があるが、今回の持参機材は 0件
      final schedule = DiveSchedule(
        id: 'test-empty-target',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: DateTime(2026, 10, 2),
        destination: '伊豆海洋公園',
        diveShop: 'テストショップ',
        targetGearIds: [], // 0件指定
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
            gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
            diveScheduleRepositoryProvider.overrideWithValue(
              InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('今回持参する機材が未選択です。'), findsOneWidget);
      expect(find.text('持参機材を選択する'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('2376x968端末等（幅360px）で持ち物チェックリストが表示されてもオーバーフローしないこと',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      final schedule = DiveSchedule(
        id: 'test-gear-responsive',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: DateTime(2026, 10, 2),
        destination: '伊豆海洋公園',
        diveShop: 'テストショップ',
        checkedGearIds: ['gear-1'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marineWeatherRepositoryProvider.overrideWithValue(MockTestWeatherRepository()),
            gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
            diveScheduleRepositoryProvider.overrideWithValue(
              InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
