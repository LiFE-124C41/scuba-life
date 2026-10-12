import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/logbook/interface/views/dive_log_page.dart';

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
  group('DiveLogPage Compact List Widget Tests', () {
    late MockDiveLogRepository mockRepo;
    late DiveLog testLog;

    setUp(() {
      mockRepo = MockDiveLogRepository();
      testLog = DiveLog(
        id: 'list-test-log-1',
        date: DateTime(2026, 9, 28),
        entryTime: DateTime(2026, 9, 28, 10, 0),
        exitTime: DateTime(2026, 9, 28, 10, 45),
        location: '伊豆・海洋公園（IOP）',
        rating: 4,
        maxDepthMeter: 21.0,
        avgDepthMeter: 13.0,
        startPressureBar: 200,
        endPressureBar: 50,
      );
      mockRepo.saveLog(testLog);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          diveLogRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: DiveLogPage(),
        ),
      );
    }

    testWidgets('一覧表示: 日付、ポイント名、評価、最大深度がコンパクトに表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ポイント名
      expect(find.text('伊豆・海洋公園（IOP）'), findsOneWidget);
      // 日付
      expect(find.text('2026/09/28'), findsOneWidget);
      // 最大深度
      expect(find.text('最大 21.0m'), findsOneWidget);
    });

    testWidgets('タップ時: 詳細画面（DiveLogDetailPage）に遷移すること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // リストアイテムをタップ
      await tester.tap(find.text('伊豆・海洋公園（IOP）'));
      await tester.pumpAndSettle();

      // 詳細画面に遷移していることを確認
      expect(find.text('ダイブデータ & 気圧実績'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.text('このログを編集する'), findsOneWidget);
    });
  });
}
