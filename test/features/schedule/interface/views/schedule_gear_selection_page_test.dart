import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/infrastructure/repositories/in_memory_gear_repository.dart';
import 'package:scuba_life/features/my_gear/interface/controllers/gear_controller.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/infrastructure/repositories/in_memory_dive_schedule_repository.dart';
import 'package:scuba_life/features/schedule/interface/controllers/schedule_controller.dart';
import 'package:scuba_life/features/schedule/interface/views/schedule_gear_selection_page.dart';

void main() {
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
    GearItem(
      id: 'gear-3',
      name: 'Mares クアッドライト',
      category: GearCategory.accessories,
      brand: 'Mares',
      purchaseDate: DateTime(2023, 3, 1),
    ),
  ];

  testWidgets('ScheduleGearSelectionPage: targetGearIds未設定時は全選択状態で初期化されること',
      (WidgetTester tester) async {
    // Arrange: targetGearIds が null
    final schedule = DiveSchedule(
      id: 'sch-select-1',
      title: '伊豆海洋公園 ファンダイブ',
      eventDate: DateTime(2026, 10, 2),
      destination: '伊豆海洋公園',
      diveShop: 'オーシャンダイブ',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
          diveScheduleRepositoryProvider.overrideWithValue(
            InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
          ),
        ],
        child: MaterialApp(
          home: ScheduleGearSelectionPage(schedule: schedule),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert: 全3件選択中
    expect(find.text('持参機材の選択'), findsOneWidget);
    expect(find.text('3 / 3 点 選択中'), findsOneWidget);
    expect(find.text('全解除'), findsOneWidget);

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(checkboxes.length, 3);
    for (final cb in checkboxes) {
      expect(cb.value, isTrue);
    }
  });

  testWidgets('ScheduleGearSelectionPage: targetGearIds設定済みの場合は指定機材のみ選択されること',
      (WidgetTester tester) async {
    // Arrange: gear-1 のみ持参予定
    final schedule = DiveSchedule(
      id: 'sch-select-2',
      title: '伊豆海洋公園 ファンダイブ',
      eventDate: DateTime(2026, 10, 2),
      destination: '伊豆海洋公園',
      diveShop: 'オーシャンダイブ',
      targetGearIds: ['gear-1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
          diveScheduleRepositoryProvider.overrideWithValue(
            InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
          ),
        ],
        child: MaterialApp(
          home: ScheduleGearSelectionPage(schedule: schedule),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert: 1 / 3 点 選択中
    expect(find.text('1 / 3 点 選択中'), findsOneWidget);
    expect(find.text('全選択'), findsOneWidget);

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(checkboxes[0].value, isTrue); // gear-1
    expect(checkboxes[1].value, isFalse); // gear-2
    expect(checkboxes[2].value, isFalse); // gear-3
  });

  testWidgets('ScheduleGearSelectionPage: トグル操作および全解除・全選択が動作すること',
      (WidgetTester tester) async {
    final schedule = DiveSchedule(
      id: 'sch-select-3',
      title: '伊豆海洋公園 ファンダイブ',
      eventDate: DateTime(2026, 10, 2),
      destination: '伊豆海洋公園',
      diveShop: 'オーシャンダイブ',
      targetGearIds: ['gear-1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
          diveScheduleRepositoryProvider.overrideWithValue(
            InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
          ),
        ],
        child: MaterialApp(
          home: ScheduleGearSelectionPage(schedule: schedule),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Act 1: gear-2 をタップして追加
    await tester.tap(find.text('SUUNTO D5 ダイブコンピューター'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3 点 選択中'), findsOneWidget);

    // Act 2: 全選択をタップ
    await tester.tap(find.text('全選択'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3 点 選択中'), findsOneWidget);
    expect(find.text('全解除'), findsOneWidget);

    // Act 3: 全解除をタップ
    await tester.tap(find.text('全解除'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 3 点 選択中'), findsOneWidget);
    expect(find.text('持参機材なし'), findsOneWidget);
  });

  testWidgets('ScheduleGearSelectionPage: 決定ボタン押下で更新が実行されること',
      (WidgetTester tester) async {
    final schedule = DiveSchedule(
      id: 'sch-save-1',
      title: '伊豆海洋公園 ファンダイブ',
      eventDate: DateTime(2026, 10, 2),
      destination: '伊豆海洋公園',
      diveShop: 'オーシャンダイブ',
      targetGearIds: ['gear-1', 'gear-2'],
    );

    final container = ProviderContainer(
      overrides: [
        gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
        diveScheduleRepositoryProvider.overrideWithValue(
          InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 初期スケジュールをロードしておく
    await container.read(scheduleCalendarProvider.notifier).loadSchedules();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScheduleGearSelectionPage(schedule: schedule),
                    ),
                  );
                },
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 選択画面を開く
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    // Act: gear-2 をタップして外す -> gear-1 のみ選択状態にする
    await tester.tap(find.text('SUUNTO D5 ダイブコンピューター'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3 点 選択中'), findsOneWidget);

    // 決定するを押下
    await tester.tap(find.text('決定する'));
    await tester.pumpAndSettle();

    // Assert: リポジトリ側のスケジュールが更新されていること
    final calendarState = container.read(scheduleCalendarProvider);
    final updatedSchedule = calendarState.schedules.firstWhere((s) => s.id == 'sch-save-1');
    expect(updatedSchedule.targetGearIds, ['gear-1']);
  });

  testWidgets('ScheduleGearSelectionPage: 幅360px（2376x968等）でオーバーフローなく描画できること',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    final schedule = DiveSchedule(
      id: 'sch-resp-1',
      title: '伊豆海洋公園 ファンダイブ',
      eventDate: DateTime(2026, 10, 2),
      destination: '伊豆海洋公園',
      diveShop: 'オーシャンダイブ',
      targetGearIds: ['gear-1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gearRepositoryProvider.overrideWithValue(InMemoryGearRepository(initialData: sampleGears)),
          diveScheduleRepositoryProvider.overrideWithValue(
            InMemoryDiveScheduleRepository(initialSchedules: [schedule]),
          ),
        ],
        child: MaterialApp(
          home: ScheduleGearSelectionPage(schedule: schedule),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
