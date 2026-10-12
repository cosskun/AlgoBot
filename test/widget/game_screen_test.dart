import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algobot_flutter/models/age_mode.dart';
import 'package:algobot_flutter/screens/game_screen.dart';
import 'package:algobot_flutter/screens/age_selection_screen.dart';
import 'package:algobot_flutter/services/locale_service.dart';
import 'package:algobot_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting(
      hasSelectedAge: true,
      ageMode: AgeMode.explorer,
      avatarId: 'classic_robi',
      unlockedLevelId: 10,
      levelStars: {1: 3, 2: 3, 3: 2},
      languageCode: 'tr',
    );
    LocaleService.instance.init();
  });

  group('GameScreen - Explorer Mode Tests', () {
    testWidgets('Renders AppBar, canvas grid, drawer and action buttons cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            initialAgeMode: AgeMode.explorer,
            initialLevelIndex: 7, // 8. Bölüm
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Header checks
      expect(find.textContaining('8. Bölüm'), findsOneWidget);
      expect(find.byTooltip('Ana Menüye Dön'), findsOneWidget);
      expect(find.byTooltip(LocaleService.instance.tr('hint')), findsOneWidget);
      expect(find.byTooltip('Harita'), findsOneWidget);
      expect(find.byTooltip('Menü'), findsOneWidget);

      // 2. Action buttons
      expect(find.text(LocaleService.instance.tr('run')), findsOneWidget);
      expect(find.text(LocaleService.instance.tr('step')), findsOneWidget);
      expect(find.text(LocaleService.instance.tr('reset')), findsOneWidget);

      // 3. Command Drawer
      expect(find.textContaining(LocaleService.instance.tr('commandDrawer')), findsOneWidget);
      expect(find.text('İleri Git'), findsOneWidget);
      expect(find.text('Sola Dön'), findsOneWidget);
      expect(find.text('Sağa Dön'), findsOneWidget);
    });

    testWidgets('Can add command blocks from drawer to workspace', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            initialAgeMode: AgeMode.explorer,
            initialLevelIndex: 0,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Initially empty workspace message
      expect(find.textContaining('Buraya komut blokları ekle!'), findsOneWidget);

      // Tap 'İleri Git' in the drawer
      final forwardBlock = find.text('İleri Git');
      expect(forwardBlock, findsOneWidget);
      await tester.tap(forwardBlock);
      await tester.pump(const Duration(milliseconds: 200));

      // Empty workspace placeholder is replaced with the added block
      expect(find.textContaining('Buraya komut blokları ekle!'), findsNothing);
      expect(find.text('İleri Git'), findsWidgets); // 1 in drawer, 1 in workspace
    });

    testWidgets('Opens hint dialog and closes it', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            initialAgeMode: AgeMode.explorer,
            initialLevelIndex: 0,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final hintButton = find.byTooltip(LocaleService.instance.tr('hint'));
      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Hint dialog is open
      expect(find.text(LocaleService.instance.tr('hint')), findsWidgets);
      final okBtn = find.textContaining('Anladım');
      expect(okBtn, findsOneWidget);

      // Close hint
      await tester.tap(okBtn);
      await tester.pump(const Duration(milliseconds: 300));
      expect(okBtn, findsNothing);
    });

    testWidgets('Opens 3-dots more options sheet and can return to main menu', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            initialAgeMode: AgeMode.explorer,
            initialLevelIndex: 0,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final menuButton = find.byTooltip('Menü');
      await tester.tap(menuButton);
      await tester.pump(const Duration(milliseconds: 300));

      final returnBtn = find.text('Ana Sayfaya Dön');
      expect(returnBtn, findsOneWidget);
      await tester.ensureVisible(returnBtn);
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 'Ana Sayfaya Dön'
      await tester.tap(returnBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Navigated back to AgeSelectionScreen
      expect(find.byType(AgeSelectionScreen), findsOneWidget);
    });
  });

  group('GameScreen - Master Mode Tests', () {
    testWidgets('Renders MAIN and F1 function tabs and advanced blocks', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            initialAgeMode: AgeMode.master,
            initialLevelIndex: 99, // Level 100 has enableFunctionF1: true and ifObstacle
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tabs
      expect(find.textContaining('Ana Kod'), findsOneWidget);
      expect(find.textContaining('F1'), findsWidgets);

      // Switch to F1 tab
      await tester.tap(find.textContaining('F1').first);
      await tester.pump(const Duration(milliseconds: 200));

      // Advanced command blocks in drawer
      expect(find.text('Eğer Engel Varsa'), findsOneWidget);
    });
  });

  group('GameScreen - Mini Mode Tests', () {
    testWidgets('Renders large instant touch buttons and handles touch navigation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            initialAgeMode: AgeMode.mini,
            initialLevelIndex: 0,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Instant buttons
      final fwd = find.text('İLERİ');
      final left = find.text('Sola');
      final right = find.text('Sağa');

      expect(fwd, findsOneWidget);
      expect(left, findsOneWidget);
      expect(right, findsOneWidget);

      // Tap turn buttons
      await tester.tap(left);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(right);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(fwd);
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
