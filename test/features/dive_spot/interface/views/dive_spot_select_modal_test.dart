import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/dive_spot/domain/entities/dive_spot.dart';
import 'package:scuba_life/features/dive_spot/interface/views/dive_spot_select_modal.dart';

void main() {
  testWidgets('DiveSpotSelectModal: 初期ポイント一覧とお気に入りフィルタ、検索機能の動作確認', (tester) async {
    // Arrange: テスト用画面
    DiveSpot? selectedSpot;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedSpot = await DiveSpotSelectModal.show(context);
                },
                child: const Text('スポット選択を開く'),
              ),
            ),
          ),
        ),
      ),
    );

    // Act: ボタンをタップしてモーダルを表示
    await tester.tap(find.text('スポット選択を開く'));
    await tester.pumpAndSettle();

    // Assert: モーダルのヘッダーと代表的な初期スポットが表示されていること
    expect(find.text('ダイビングポイント選択'), findsOneWidget);
    expect(find.text('新規登録'), findsOneWidget);
    expect(find.text('大瀬崎 湾内'), findsOneWidget);
    expect(find.text('伊豆海洋公園 (IOP)'), findsOneWidget);

    // Act: 検索窓に「ケラマ」を入力
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, '慶良間');
    await tester.pumpAndSettle();

    // Assert: 慶良間諸島のスポットのみがフィルタ表示されること
    expect(find.text('慶良間諸島・北浜(ニシバマ)'), findsOneWidget);
    expect(find.text('大瀬崎 湾内'), findsNothing);

    // Act: 慶良間諸島を選択
    await tester.tap(find.text('慶良間諸島・北浜(ニシバマ)'));
    await tester.pumpAndSettle();

    // Assert: モーダルが閉じ、選択されたスポットが返されること
    expect(find.byType(DiveSpotSelectModal), findsNothing);
    expect(selectedSpot, isNotNull);
    expect(selectedSpot!.name, '慶良間諸島・北浜(ニシバマ)');
    expect(selectedSpot!.latitude, 26.2083);
  });
}
