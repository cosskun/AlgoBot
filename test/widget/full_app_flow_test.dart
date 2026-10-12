import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algobot_flutter/models/age_mode.dart';
import 'package:algobot_flutter/screens/age_selection_screen.dart';
import 'package:algobot_flutter/screens/game_screen.dart';
import 'package:algobot_flutter/services/locale_service.dart';
import 'package:algobot_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting(
      hasSelectedAge: false,
      ageMode: AgeMode.explorer,
      avatarId: 'classic_robi',
      unlockedLevelId: 5,
      levelStars: {1: 3, 2: 3, 3: 2},
      languageCode: 'tr',
    );
    LocaleService.instance.init();
  });

  group('AgeSelectionScreen Full Flow & Responsiveness Tests', () {
    final testScreenSizes = [
      const Size(360, 640),  // Compact Android phone
      const Size(393, 852),  // iPhone 15 / 16 Pro
      const Size(412, 915),  // Large Android phone (Samsung Galaxy S / Plus)
      const Size(768, 1024), // Tablet / iPad
    ];

    for (final size in testScreenSizes) {
      testWidgets('Renders without overflow on screen size ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: AgeSelectionScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Verify key headers and cards render
        expect(find.text('AlgoKids'), findsOneWidget);
        expect(find.textContaining('Mini Mod'), findsOneWidget);
        expect(find.textContaining('Kaşif Modu'), findsOneWidget);
        expect(find.textContaining('Usta Kodlayıcı'), findsOneWidget);
        expect(find.textContaining('Günün Bulmacası'), findsOneWidget);
      });
    }

    testWidgets('Toggles language smoothly between Turkish and English', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AgeSelectionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Initially in Turkish
      expect(find.textContaining('Kaç Yaşındasın'), findsOneWidget);

      // Tap language switch button in top bar
      final langButton = find.byTooltip('Dil / Language');
      expect(langButton, findsOneWidget);
      await tester.tap(langButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Now in English
      expect(find.textContaining('How Old Are You'), findsOneWidget);

      // Tap language switch button again to return to Turkish
      await tester.tap(langButton);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Kaç Yaşındasın'), findsOneWidget);
    });

    testWidgets('Opens Star Mystery Chests dialog and closes it', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AgeSelectionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final chestButton = find.byTooltip(LocaleService.instance.tr('mysteryChest'));
      expect(chestButton, findsOneWidget);
      await tester.tap(chestButton);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Dialog is open
      expect(find.textContaining('Yıldız Sandıkları'), findsWidgets);
      expect(find.textContaining('Toplam Yıldız: 8'), findsOneWidget);

      // Close dialog
      final closeButton = find.text('Kapat');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Kapat'), findsNothing);
    });

    testWidgets('Opens 3-dots menu sheet and interacts with options', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AgeSelectionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final menuButton = find.byTooltip('Menü');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Bottom sheet is visible
      expect(find.textContaining('Gelişim Raporu'), findsOneWidget);
      expect(find.textContaining('Çıkartma Albümü'), findsOneWidget);
      expect(find.textContaining('Kendi Bölümünü Çiz'), findsOneWidget);
    });

    testWidgets('Tapping Mini Mod card navigates to GameScreen with instant touch buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AgeSelectionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final miniCard = find.textContaining('Mini Mod');
      await tester.ensureVisible(miniCard);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(miniCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // In GameScreen Mini Mode, large touch buttons are present
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('İLERİ'), findsOneWidget);
      expect(find.text('Sola'), findsOneWidget);
      expect(find.text('Sağa'), findsOneWidget);
      expect(find.textContaining('1. Bölüm'), findsOneWidget);
    });
  });
}
