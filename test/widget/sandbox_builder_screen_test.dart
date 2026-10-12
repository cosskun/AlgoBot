import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algobot_flutter/models/avatar_model.dart';
import 'package:algobot_flutter/screens/sandbox_level_builder_screen.dart';
import 'package:algobot_flutter/services/locale_service.dart';
import 'package:algobot_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting();
    LocaleService.instance.init();
  });

  group('SandboxLevelBuilderScreen Tests', () {
    testWidgets('Renders toolbar, grid and tool selector cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SandboxLevelBuilderScreen(
            avatar: AvatarModel.allAvatars.first,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Title
      expect(find.textContaining('Kendi Bölümünü Çiz'), findsOneWidget);

      // Action buttons in AppBar
      expect(find.byTooltip(LocaleService.instance.tr('shareLevel')), findsOneWidget);
      expect(find.byTooltip(LocaleService.instance.tr('importLevel')), findsOneWidget);
      expect(find.textContaining('Test'), findsOneWidget);

      // Tools in selector bar
      expect(find.textContaining('Taş'), findsOneWidget);
      expect(find.textContaining('Yıldız'), findsOneWidget);
      expect(find.textContaining('Robi'), findsOneWidget);
      expect(find.textContaining('Hedef'), findsOneWidget);
      expect(find.textContaining('Anahtar'), findsOneWidget);
      expect(find.textContaining('Kapı'), findsOneWidget);
      expect(find.textContaining('Silgi'), findsOneWidget);
    });

    testWidgets('Can select tools and open Share / Import dialogs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SandboxLevelBuilderScreen(
            avatar: AvatarModel.allAvatars.first,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Select 'Yıldız' tool
      await tester.tap(find.textContaining('Yıldız'));
      await tester.pump(const Duration(milliseconds: 200));

      // 2. Open Share dialog
      final shareBtn = find.byTooltip(LocaleService.instance.tr('shareLevel'));
      await tester.tap(shareBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(LocaleService.instance.tr('shareLevel')), findsWidgets);
      expect(find.text(LocaleService.instance.tr('copyCode')), findsOneWidget);

      // Close share dialog
      await tester.tap(find.text(LocaleService.instance.tr('copyCode')));
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Open Import dialog
      final importBtn = find.byTooltip(LocaleService.instance.tr('importLevel'));
      await tester.tap(importBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(LocaleService.instance.tr('importLevel')), findsWidgets);
      expect(find.text('İptal'), findsOneWidget);

      // Close import dialog
      await tester.tap(find.text('İptal'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('İptal'), findsNothing);
    });

    testWidgets('Toggles between editing mode and Test Play mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SandboxLevelBuilderScreen(
            avatar: AvatarModel.allAvatars.first,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Initially in editing mode: 'Test' button is visible
      final testBtn = find.textContaining('Test');
      expect(testBtn, findsOneWidget);

      // Switch to Play mode
      await tester.tap(testBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // In play mode: 'Düzenle' (Edit) button appears, along with Run/Step
      expect(find.textContaining('Düzenle'), findsOneWidget);
      expect(find.text(LocaleService.instance.tr('run')), findsOneWidget);
      expect(find.text(LocaleService.instance.tr('reset')), findsOneWidget);

      // Switch back to edit mode
      await tester.tap(find.textContaining('Düzenle'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Test'), findsOneWidget);
    });
  });
}
