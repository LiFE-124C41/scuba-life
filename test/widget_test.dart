import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/app/app.dart';

void main() {
  testWidgets('ScubaLifeApp smoke test - 初期画面の描画確認', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScubaLifeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // ログブックのタイトルが表示されていることを確認
    expect(find.text('ダイビングログ'), findsOneWidget);
    // ナビゲーションバーの各項目が表示されていることを確認
    expect(find.text('生き物図鑑'), findsOneWidget);
    expect(find.text('予定管理'), findsOneWidget);
    expect(find.text('機材管理'), findsOneWidget);
    expect(find.text('セール情報'), findsNothing);
    expect(find.text('海況・気象'), findsNothing);
  });
}
