import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/logbook/interface/views/dive_log_detail_page.dart';

class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> storage = [];

  @override
  Future<List<DiveLog>> getAllLogs() async => List.from(storage);

  @override
  Future<DiveLog?> getLogById(String id) async =>
      storage.where((log) => log.id == id).firstOrNull;

  @override
  Future<void> saveLog(DiveLog log) async {
    storage.removeWhere((l) => l.id == log.id);
    storage.add(log);
  }

  @override
  Future<void> deleteLog(String id) async {
    storage.removeWhere((l) => l.id == id);
  }
}

void main() {
  group('DiveLogDetailPage Widget Tests', () {
    late MockDiveLogRepository mockRepo;
    late DiveLog testLog;

    setUp(() {
      mockRepo = MockDiveLogRepository();
      testLog = DiveLog(
        id: 'detail-test-log-1',
        entryTime: DateTime(2026, 9, 28, 10, 0),
        exitTime: DateTime(2026, 9, 28, 10, 45),
        location: '伊豆・大瀬崎（先端）',
        diveCenter: '大瀬マリンサービス',
        rating: 5,
        divePurpose: 'ファンダイビング',
        entryMethod: 'ビーチ',
        waterArea: '海洋',
        waterType: '海水',
        maxDepthMeter: 28.5,
        avgDepthMeter: 16.0,
        startPressureBar: 200,
        endPressureBar: 50,
        tankVolumeLiter: 10.0,
        cylinderMaterial: 'スチール',
        weightKg: 4.5,
        weather: '晴れ',
        airTemp: 25.0,
        waterTempMin: 20.0,
        waterTempMax: 22.0,
        visibilityMeter: 20.0,
        underwaterCurrent: '弱',
        surfaceCurrent: '穏やか',
        tideType: '大潮',
        buddies: ['斉藤バディ'],
        marineLife: ['キンギョハナダイ', 'タカベ'],
        equipment: '5mmフルスーツ',
        notes: '先端ならではの魚影の濃さに感動。',
      );
      mockRepo.saveLog(testLog);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          diveLogRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: DiveLogDetailPage(logId: 'detail-test-log-1'),
        ),
      );
    }

    testWidgets('詳細描画: 全情報（ポイント、評価、深度、SACレート、海況、バディ、生物）が表示されること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ヘッダー情報
      expect(find.text('伊豆・大瀬崎（先端）'), findsWidgets); // AppBarとカード
      expect(find.text('大瀬マリンサービス'), findsOneWidget);
      expect(find.text('ファンダイビング'), findsOneWidget);

      // ダイブ実績 & SAC
      expect(find.text('28.5 m'), findsOneWidget);
      expect(find.text('45 分'), findsOneWidget);
      expect(find.textContaining('SACレート'), findsOneWidget);

      // 海況・バディ・生物
      expect(find.text('大潮'), findsOneWidget);
      expect(find.text('斉藤バディ'), findsOneWidget);
      expect(find.text('キンギョハナダイ'), findsOneWidget);
      expect(find.text('先端ならではの魚影の濃さに感動。'), findsOneWidget);
    });

    testWidgets('編集ボタンタップ: 編集画面へ遷移できること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // AppBarの編集アイコン
      final editIcon = find.byIcon(Icons.edit_outlined);
      expect(editIcon, findsOneWidget);

      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // 編集画面タイトルが表示されること
      expect(find.text('ログを編集'), findsOneWidget);
    });
  });
}
