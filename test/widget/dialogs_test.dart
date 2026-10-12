import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/models/age_mode.dart';
import 'package:algobot_flutter/models/avatar_model.dart';
import 'package:algobot_flutter/widgets/avatar_selector_dialog.dart';
import 'package:algobot_flutter/widgets/celebration_dialog.dart';
import 'package:algobot_flutter/widgets/profile_dialog.dart';
import 'package:algobot_flutter/widgets/sticker_album_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CelebrationDialog Tests', () {
    testWidgets('Renders 3-star victory and triggers buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool nextClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationDialog(
              starsEarned: 3,
              blocksUsed: 6,
              maxBlocksFor3Stars: 8,
              onNextLevel: () => nextClicked = true,
              onReplay: () {},
              onWatchSolution: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Bölüm Tamamlandı!'), findsOneWidget);
      expect(find.textContaining('3. Yıldız: En Verimli Algoritma'), findsOneWidget);
      expect(find.text('Sonraki Bölüm ➔'), findsOneWidget);
      expect(find.text('↺ Tekrar'), findsOneWidget);

      await tester.tap(find.text('Sonraki Bölüm ➔'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(nextClicked, isTrue);
    });

    testWidgets('Renders 2-star victory with Watch Solution button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool watchClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationDialog(
              starsEarned: 2,
              blocksUsed: 12,
              maxBlocksFor3Stars: 8,
              onNextLevel: () {},
              onReplay: () {},
              onWatchSolution: () => watchClicked = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final watchBtn = find.textContaining('Çözümü İzle');
      expect(watchBtn, findsOneWidget);

      await tester.tap(watchBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(watchClicked, isTrue);
    });
  });

  group('AvatarSelectorDialog Tests', () {
    testWidgets('Renders costumes and selecting unlocked avatar invokes callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      AvatarModel? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarSelectorDialog(
              currentAvatarId: 'classic_robi',
              unlockedAvatarIds: const {'classic_robi', 'astro_robi'},
              onSelectAvatar: (a) => selected = a,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Robi Kostüm Dolabı'), findsOneWidget);
      expect(find.text('Klasik Robi'), findsOneWidget);
      expect(find.text('Astro Robi'), findsOneWidget);

      // Tap 'Astro Robi'
      await tester.tap(find.text('Astro Robi'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(selected, isNotNull);
      expect(selected!.id, equals('astro_robi'));
    });
  });

  group('StickerAlbumDialog Tests', () {
    testWidgets('Renders unlocked stickers and progress bar cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerAlbumDialog(
              unlockedLevelId: 25,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Çıkartma Albümü'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('ProfileDialog Tests', () {
    testWidgets('Renders mastery bars, stars and current avatar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool changeAgeClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileDialog(
              unlockedLevelId: 65,
              totalStars: 180,
              currentAvatar: AvatarModel.allAvatars.first,
              currentAgeMode: AgeMode.master,
              onChangeAgeMode: () => changeAgeClicked = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Gelişim Raporu'), findsOneWidget);
      expect(find.textContaining('180 ⭐'), findsOneWidget);
      expect(find.textContaining('65 / 100'), findsOneWidget);

      // Age mode change button
      final ageBtn = find.textContaining('Yaş Grubunu Değiştir');
      expect(ageBtn, findsOneWidget);
      await tester.tap(ageBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(changeAgeClicked, isTrue);
    });
  });
}
