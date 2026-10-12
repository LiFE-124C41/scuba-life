import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/domain/repositories/dive_schedule_repository.dart';
import 'package:scuba_life/features/schedule/interface/controllers/schedule_controller.dart';
import 'package:scuba_life/features/schedule/interface/views/schedule_page.dart';
import 'package:scuba_life/features/schedule/interface/views/widgets/schedule_detail_sheet.dart';

class MockScheduleRepositoryForWidget implements DiveScheduleRepository {
  final List<DiveSchedule> _items;

  MockScheduleRepositoryForWidget(this._items);

  @override
  Future<List<DiveSchedule>> getUpcomingSchedules() async => _items;

  @override
  Future<void> addSchedule(DiveSchedule schedule) async {
    _items.add(schedule);
  }

  @override
  Future<void> updateSchedule(DiveSchedule schedule) async {
    final index = _items.indexWhere((item) => item.id == schedule.id);
    if (index != -1) {
      _items[index] = schedule;
    } else {
      _items.add(schedule);
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

void main() {
  testWidgets('SchedulePage: カレンダーと予定一覧および詳細モーダルが表示されること', (tester) async {
    // 画面サイズを広げて十分な表示領域を確保
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Arrange: テスト実行時の現在日時に合わせたサンプルデータを用意
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final mockSchedules = [
      DiveSchedule(
        id: 'sch-today',
        title: '伊豆海洋公園テストダイブ',
        eventDate: today,
        destination: '伊豆海洋公園 (IOP)',
        diveShop: 'オーシャンダイブ',
        plannedDivesCount: 2,
        memo: '水中ポスト前集合。ポスト投函用ハガキ持参。',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diveScheduleRepositoryProvider.overrideWithValue(
            MockScheduleRepositoryForWidget(mockSchedules),
          ),
        ],
        child: const MaterialApp(
          home: SchedulePage(),
        ),
      ),
    );

    // Act: 初期描画完了まで待機
    await tester.pumpAndSettle();

    // Assert: タイトルとカレンダーの基本構成が表示されていること
    expect(find.text('ダイビング予定'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
    expect(find.text('日'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('土'), findsOneWidget);

    final scheduleCardFinder = find.text('伊豆海洋公園テストダイブ').first;
    await tester.ensureVisible(scheduleCardFinder);
    await tester.pumpAndSettle();

    // 本日の予定カードが表示されていること
    expect(find.text('伊豆海洋公園テストダイブ'), findsAtLeastNWidgets(1));
    expect(find.text('伊豆海洋公園 (IOP)'), findsAtLeastNWidgets(1));
    expect(find.text('2ダイブ'), findsAtLeastNWidgets(1));

    // Act: 予定カードをタップして詳細モーダルを開く
    await tester.tap(scheduleCardFinder);
    await tester.pumpAndSettle();

    // Assert: 詳細モーダルシートが開かれ、詳細情報（メモやショップ、ダイブ本数、ログ連携）が表示されること
    expect(find.byType(ScheduleDetailSheet), findsOneWidget);
    expect(find.text('利用ダイブショップ'), findsOneWidget);
    expect(find.text('水中ポスト前集合。ポスト投函用ハガキ持参。'), findsOneWidget);
    expect(find.text('記録済みダイビングログ'), findsOneWidget);
    expect(find.text('この予定からログを記録する'), findsOneWidget);

    final closeBtnFinder = find.text('閉じる');
    await tester.ensureVisible(closeBtnFinder);
    await tester.pumpAndSettle();

    // Act: 閉じるボタンをタップ
    await tester.tap(closeBtnFinder);
    await tester.pumpAndSettle();

    // Assert: モーダルが閉じられたこと
    expect(find.byType(ScheduleDetailSheet), findsNothing);

    // Act: AppBar のマップ切替アイコンをタップ
    final mapToggleFinder = find.byTooltip('マップ表示に切替');
    expect(mapToggleFinder, findsOneWidget);
    await tester.tap(mapToggleFinder);
    await tester.pumpAndSettle();

    // Assert: カレンダー表示アイコンが表示され、マップビュー状態になっていること
    expect(find.byTooltip('カレンダー表示に切替'), findsOneWidget);
  });
}
