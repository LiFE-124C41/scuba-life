import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_statistics.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_statistics_controller.dart';
import 'package:scuba_life/features/logbook/interface/views/dive_log_page.dart';
import 'package:scuba_life/features/logbook/interface/views/dive_log_statistics_page.dart';

class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> logs = [];

  @override
  Future<List<DiveLog>> getAllLogs() async => List.from(logs);

  @override
  Future<DiveLog?> getLogById(String id) async =>
      logs.where((l) => l.id == id).firstOrNull;

  @override
  Future<void> saveLog(DiveLog log) async {
    logs.removeWhere((l) => l.id == log.id);
    logs.add(log);
  }

  @override
  Future<void> deleteLog(String id) async {
    logs.removeWhere((l) => l.id == id);
  }
}

void main() {
  group('DiveLogStatisticsPage & SummaryCard Widget Tests', () {
    final sampleLogs = [
      DiveLog(
        id: 'log-stat-1',
        entryTime: DateTime(2026, 9, 20, 10, 0),
        exitTime: DateTime(2026, 9, 20, 10, 45), // 45分
        location: '大瀬崎 先端',
        maxDepthMeter: 28.0,
        avgDepthMeter: 16.0,
        startPressureBar: 200,
        endPressureBar: 50,
        tankVolumeLiter: 10.0,
        entryMethod: 'ボート',
        underwaterCurrent: '中',
        rating: 5,
      ),
      DiveLog(
        id: 'log-stat-2',
        entryTime: DateTime(2026, 9, 10, 9, 0),
        exitTime: DateTime(2026, 9, 10, 9, 40), // 40分
        location: '伊豆海洋公園',
        maxDepthMeter: 18.0,
        avgDepthMeter: 12.0,
        startPressureBar: 200,
        endPressureBar: 70,
        tankVolumeLiter: 10.0,
        entryMethod: 'ビーチ',
        underwaterCurrent: 'なし',
        rating: 4,
      ),
    ];

    testWidgets('統計画面: ログが存在する場合に総本数・最大深度・累計時間・エントリー比率が表示されること',
        (tester) async {
      // Arrange (準備)
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      final stats = DiveStatistics.fromLogs(
        sampleLogs,
        referenceDate: DateTime(2026, 9, 30),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diveStatisticsProvider.overrideWithValue(AsyncData(stats)),
          ],
          child: const MaterialApp(
            home: DiveLogStatisticsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert (検証)
      // 画面タイトル
      expect(find.text('ダイバー統計・スキルシート'), findsOneWidget);
      // 総本数
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Dives (本)'), findsOneWidget);
      // 最大水深
      expect(find.text('28.0 m'), findsOneWidget);
      // 累計潜水時間 (45 + 40 = 85分 => 1時間 25分)
      expect(find.text('1時間 25分'), findsOneWidget);
      // エントリー形式
      expect(find.textContaining('ボート: 1本'), findsOneWidget);
      expect(find.textContaining('ビーチ: 1本'), findsOneWidget);
      // 潮流
      expect(find.text('中潮流'), findsOneWidget);
      // 直近潜水実績
      expect(find.text('大瀬崎 先端'), findsOneWidget);
      expect(find.text('伊豆海洋公園'), findsOneWidget);
    });

    testWidgets('統計画面: 小型画面（幅360px）でもオーバーフローせずに正常に描画できること',
        (tester) async {
      // Arrange (準備)
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      final stats = DiveStatistics.fromLogs(
        sampleLogs,
        referenceDate: DateTime(2026, 9, 30),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diveStatisticsProvider.overrideWithValue(AsyncData(stats)),
          ],
          child: const MaterialApp(
            home: DiveLogStatisticsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert (検証): 小型画面でもオーバーフロー等の描画例外が発生していないこと
      expect(tester.takeException(), isNull);
    });

    testWidgets('統計画面: ログが0件の場合は空ステートの案内が表示されること', (tester) async {
      // Arrange (準備)
      final emptyStats = DiveStatistics.empty();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diveStatisticsProvider.overrideWithValue(AsyncData(emptyStats)),
          ],
          child: const MaterialApp(
            home: DiveLogStatisticsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert (検証)
      expect(find.text('ダイブログがまだ登録されていません'), findsOneWidget);
      expect(find.textContaining('インストラクターに見せるための統計'), findsOneWidget);
    });

    testWidgets('ログ一覧画面: サマリーカードおよびAppBar統計アイコンが表示され、タップで統計画面へ遷移できること',
        (tester) async {
      // Arrange (準備)
      final mockRepo = MockDiveLogRepository();
      mockRepo.logs.addAll(sampleLogs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diveLogRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DiveLogPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: サマリーカードがリスト上部に表示されていること
      expect(find.text('ダイバーサマリー'), findsOneWidget);
      expect(find.text('統計詳細'), findsOneWidget);

      // AppBarの統計アイコンボタンをタップ
      final insightsIcon = find.byIcon(Icons.insights);
      expect(insightsIcon, findsWidgets); // AppBarとサマリーカード内の2箇所
      await tester.tap(insightsIcon.first);
      await tester.pumpAndSettle();

      // Assert: 統計画面に遷移していること
      expect(find.text('ダイバー統計・スキルシート'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
