import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/logbook/interface/views/dive_log_form_page.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';

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
  group('DiveLogFormPage Widget Tests', () {
    late MockDiveLogRepository mockRepo;

    setUp(() {
      mockRepo = MockDiveLogRepository();
    });

    Widget createTestWidget({DiveLog? initialLog, DiveSchedule? initialSchedule}) {
      return ProviderScope(
        overrides: [
          diveLogRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: DiveLogFormPage(
            initialLog: initialLog,
            initialSchedule: initialSchedule,
          ),
        ),
      );
    }

    testWidgets('初期描画: タイトルおよび基本セクションが表示されること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // タイトルの確認
      expect(find.text('ログを追加'), findsOneWidget);

      // セクションヘッダーの確認
      expect(find.text('基本情報 & 評価'), findsOneWidget);
      expect(find.text('潜水時間・エントリー・水域'), findsOneWidget);
      expect(find.text('深度 & 気圧（実績と計画）'), findsOneWidget);
      expect(find.text('海況・環境・潮流・潮汐'), findsOneWidget);
      expect(find.text('機材・シリンダー・ウェイト'), findsOneWidget);
      expect(find.text('バディ・生物・メモ'), findsOneWidget);
    });

    testWidgets('バディ追加機能: テキストを入力して追加ボタンを押すとチップが表示されること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // バディ入力欄を探す
      final buddyField = find.widgetWithText(TextField, 'バディ名を追加');
      expect(buddyField, findsOneWidget);

      await tester.enterText(buddyField, '高橋バディ');
      await tester.pumpAndSettle();

      // 「追加」ボタンをタップ
      final addButton = find.widgetWithText(FilledButton, '追加').first;
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // チップが描画されていることを確認
      expect(find.text('高橋バディ'), findsOneWidget);
    });

    testWidgets('既存ログ編集時: 渡されたログ情報がフォームに初期入力されていること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingLog = DiveLog(
        id: 'edit-test-id',
        entryTime: DateTime(2026, 9, 28, 10, 0),
        exitTime: DateTime(2026, 9, 28, 10, 45),
        location: '雲見・牛着岩',
        diveCenter: '雲見マリンサービス',
        rating: 5,
        maxDepthMeter: 24.0,
        avgDepthMeter: 15.0,
        startPressureBar: 200,
        endPressureBar: 60,
        buddies: ['木村ダイバー'],
        marineLife: ['キンメモドキ'],
      );

      await tester.pumpWidget(createTestWidget(initialLog: existingLog));
      await tester.pumpAndSettle();

      expect(find.text('ログを編集'), findsOneWidget);
      expect(find.text('雲見・牛着岩'), findsOneWidget);
      expect(find.text('雲見マリンサービス'), findsOneWidget);
      expect(find.text('木村ダイバー'), findsOneWidget);
      expect(find.text('キンメモドキ'), findsOneWidget);
    });

    testWidgets('予定連携作成時: 渡された予定の情報（目的地・ショップ名）がフォームに初期入力されていること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sched = DiveSchedule(
        id: 'sched-link-test',
        title: '伊豆海洋公園ツアー',
        eventDate: DateTime(2026, 10, 10),
        destination: '伊豆海洋公園 (IOP)',
        diveShop: 'オーシャンダイブサービス',
        plannedDivesCount: 2,
      );

      await tester.pumpWidget(createTestWidget(initialSchedule: sched));
      await tester.pumpAndSettle();

      expect(find.text('ログを追加'), findsOneWidget);
      expect(find.text('伊豆海洋公園 (IOP)'), findsOneWidget);
      expect(find.text('オーシャンダイブサービス'), findsOneWidget);
    });
  });
}
