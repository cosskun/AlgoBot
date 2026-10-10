import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algobot_flutter/models/age_mode.dart';
import 'package:algobot_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Unit Tests', () {
    late StorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService.instance;
      storage.resetForTesting(
        hasSelectedAge: false,
        ageMode: AgeMode.mini,
        avatarId: 'classic_robi',
        unlockedLevelId: 1,
        levelStars: {},
        languageCode: 'tr',
      );
    });

    test('Initial reset state is properly reflected', () {
      expect(storage.hasSelectedAge, isFalse);
      expect(storage.ageMode, equals(AgeMode.mini));
      expect(storage.avatarId, equals('classic_robi'));
      expect(storage.unlockedLevelId, equals(1));
      expect(storage.totalStars, equals(0));
    });

    test('Saving level progress increments unlockedLevelId and updates stars', () async {
      await storage.saveLevelProgress(1, 3);
      expect(storage.unlockedLevelId, equals(2));
      expect(storage.levelStars[1], equals(3));
      expect(storage.totalStars, equals(3));

      // Replaying level with fewer stars does not downgrade
      await storage.saveLevelProgress(1, 2);
      expect(storage.levelStars[1], equals(3));
      expect(storage.totalStars, equals(3));
    });

    test('Unlocking avatar adds to unlocked avatars set', () async {
      expect(storage.unlockedAvatars, contains('classic_robi'));
      await storage.unlockAvatar('ninja_robi');
      expect(storage.unlockedAvatars, contains('ninja_robi'));
    });

    test('Saving age mode updates mode and sets hasSelectedAge', () async {
      await storage.saveAgeMode(AgeMode.master);
      expect(storage.ageMode, equals(AgeMode.master));
      expect(storage.hasSelectedAge, isTrue);
    });
  });
}
