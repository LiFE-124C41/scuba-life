import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/domain/repositories/gear_repository.dart';
import 'package:scuba_life/features/my_gear/interface/controllers/gear_controller.dart';
import 'package:scuba_life/features/my_gear/interface/views/gear_detail_page.dart';

/// テスト用モックリポジトリ
class MockGearRepository implements GearRepository {
  final List<GearItem> items = [];

  @override
  Future<List<GearItem>> getAllGear() async => List.from(items);

  @override
  Future<GearItem?> getGearById(String id) async =>
      items.where((g) => g.id == id).firstOrNull;

  @override
  Future<void> saveGear(GearItem gear) async {
    final index = items.indexWhere((g) => g.id == gear.id);
    if (index >= 0) {
      items[index] = gear;
    } else {
      items.add(gear);
    }
  }

  @override
  Future<void> deleteGear(String id) async {
    items.removeWhere((g) => g.id == id);
  }
}

void main() {
  group('GearDetailPage Widget Tests', () {
    final sampleRegulator = GearItem(
      id: 'gear-reg-1',
      name: 'Apeks XTX200 レギュレーターセット',
      category: GearCategory.regulator,
      brand: 'Apeks',
      model: 'XTX200',
      serialNumber: 'SN-12345678',
      purchaseDate: DateTime(2025, 1, 15),
      requiresOverhaul: true,
      overhaulIntervalMonths: 12,
      overhaulIntervalDives: 100,
      divesSinceOverhaul: 35,
      memo: '2025年冬に購入。ホース保護スリーブ装着済み。',
    );

    testWidgets('機材詳細画面: 基本情報およびオーバーホール推奨情報が表示されること',
        (WidgetTester tester) async {
      // Arrange (準備)
      final mockRepo = MockGearRepository();
      mockRepo.items.add(sampleRegulator);

      // Act (実行)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gearRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GearDetailPage(gearId: 'gear-reg-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert (検証)
      expect(find.text('Apeks XTX200 レギュレーターセット'), findsWidgets);
      expect(find.text('オーバーホール目安・状況'), findsOneWidget);
      expect(find.text('OH完了を記録'), findsOneWidget);
      expect(find.text('基本情報・購入情報'), findsOneWidget);
      expect(find.text('SN-12345678'), findsOneWidget);
    });

    testWidgets('機材詳細画面: 2376x968端末等（幅360px）でもオーバーフローせずに描画できること',
        (WidgetTester tester) async {
      // Arrange (準備)
      // 2376x968端末（縦向き論理幅 約352〜368px、ここでは厳格に360x900で検証）
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      final mockRepo = MockGearRepository();
      mockRepo.items.add(sampleRegulator);

      // Act (実行)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gearRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GearDetailPage(gearId: 'gear-reg-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert (検証): オーバーフロー例外が発生していないこと
      expect(tester.takeException(), isNull);
      expect(find.text('オーバーホール目安・状況'), findsOneWidget);
      expect(find.text('OH完了を記録'), findsOneWidget);
    });
  });
}
