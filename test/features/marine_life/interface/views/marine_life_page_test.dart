import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/marine_life/interface/views/marine_life_page.dart';

class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> logs;
  MockDiveLogRepository(this.logs);

  @override
  Future<List<DiveLog>> getAllLogs() async => List.from(logs);

  @override
  Future<DiveLog?> getLogById(String id) async =>
      logs.where((l) => l.id == id).firstOrNull;

  @override
  Future<void> saveLog(DiveLog log) async {}

  @override
  Future<void> deleteLog(String id) async {}
}

void main() {
  testWidgets('MarineLifePage: 生き物一覧、月、場所が表示され、タップで詳細シートが開くこと',
      (WidgetTester tester) async {
    // Arrange
    final testLogs = [
      DiveLog(
        id: 'test-log-1',
        entryTime: DateTime(2026, 7, 20, 10, 0),
        exitTime: DateTime(2026, 7, 20, 10, 45),
        location: '伊豆大瀬崎 湾内',
        maxDepthMeter: 18.0,
        avgDepthMeter: 11.0,
        startPressureBar: 200,
        endPressureBar: 50,
        marineLife: ['アオウミガメ'],
        notes: '浅瀬で優雅に泳ぐウミガメに遭遇。',
      ),
    ];

    final mockRepo = MockDiveLogRepository(testLogs);

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diveLogRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: MarineLifePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert: 生物名・遭遇数・出現月・場所が表示されていること
    expect(find.text('生き物図鑑'), findsOneWidget);
    expect(find.text('アオウミガメ'), findsOneWidget);
    expect(find.text('1回遭遇'), findsOneWidget);
    expect(find.text('7月'), findsWidgets);
    expect(find.text('伊豆大瀬崎 湾内'), findsOneWidget);

    // Act: カードをタップして詳細モーダルを開く
    await tester.tap(find.text('アオウミガメ'));
    await tester.pumpAndSettle();

    // Assert: 詳細モーダルが展開され、遭遇ログ履歴とメモが表示されること
    expect(find.text('累計 1 回遭遇'), findsOneWidget);
    expect(find.text('遭遇ログ履歴 (1件)'), findsOneWidget);
    expect(find.text('浅瀬で優雅に泳ぐウミガメに遭遇。'), findsOneWidget);
  });

  testWidgets('MarineLifePage: ログが0件のときにエラーなく空状態UIが表示されること',
      (WidgetTester tester) async {
    // Arrange: ログが0件のリポジトリ
    final mockRepo = MockDiveLogRepository([]);

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diveLogRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: MarineLifePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert: エラーが表示されず、「記録された生き物がまだありません」が表示されること
    expect(find.textContaining('エラーが発生しました'), findsNothing);
    expect(find.text('記録された生き物がまだありません'), findsOneWidget);
  });
}
