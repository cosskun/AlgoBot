import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algobot_flutter/models/level_data.dart';
import 'package:algobot_flutter/screens/world_map_screen.dart';
import 'package:algobot_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting();
  });

  group('WorldMapScreen Tests', () {
    testWidgets('Renders all 10 world tabs, level grid and navigates on level click', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selectedLevel = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: WorldMapScreen(
            unlockedLevelId: 5,
            levelStars: const {1: 3, 2: 3, 3: 2, 4: 1},
            onSelectLevel: (lvlIdx) {
              selectedLevel = lvlIdx;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Header
      expect(find.textContaining('100 Bölüm Haritası'), findsOneWidget);

      // 10 World tabs exist in TabBar
      for (final world in LevelData.worlds) {
        expect(find.text('${world.badge} ${world.id}. Dünya'), findsWidgets);
      }

      // World 1 levels (1..10) are shown in GridView
      expect(find.text('1'), findsWidgets);
      expect(find.text('5'), findsWidgets);

      // Tap unlocked level 3 (index 2)
      final level3Node = find.text('3');
      expect(level3Node, findsWidgets);
      await tester.tap(level3Node.first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(selectedLevel, equals(2));
    });

    testWidgets('Tapping locked level displays locked snackbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selectedLevel = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldMapScreen(
              unlockedLevelId: 2, // only level 1 & 2 unlocked
              levelStars: const {1: 3},
              onSelectLevel: (lvlIdx) {
                selectedLevel = lvlIdx;
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Level 8 is locked
      final level8Node = find.text('8');
      expect(level8Node, findsWidgets);
      await tester.tap(level8Node.first);
      await tester.pump(const Duration(milliseconds: 100));

      // SnackBar shows locked message
      expect(find.textContaining('kilitli'), findsOneWidget);
      // Callback was NOT fired
      expect(selectedLevel, equals(-1));
    });
  });
}
