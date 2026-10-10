import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/main.dart';

void main() {
  testWidgets('AlgoKids app loads successfully with age selection', (WidgetTester tester) async {
    await tester.pumpWidget(const AlgoKidsApp());
    expect(find.textContaining('Mini Mod'), findsWidgets);
    expect(find.textContaining('Kaşif Modu'), findsWidgets);
    expect(find.textContaining('Usta Kodlayıcı'), findsWidgets);
  });
}
