import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/screens/age_selection_screen.dart';
import 'package:algobot_flutter/services/storage_service.dart';

void main() {
  setUp(() {
    StorageService.instance.resetForTesting();
  });

  testWidgets('AgeSelectionScreen displays all 3 age modes and header', (WidgetTester tester) async {
    // Provide a standard phone screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AgeSelectionScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Kaç Yaşındasın'), findsOneWidget);
    expect(find.textContaining('Mini Mod'), findsOneWidget);
    expect(find.textContaining('Kaşif Modu'), findsOneWidget);
    expect(find.textContaining('Usta Kodlayıcı'), findsOneWidget);
  });
}
