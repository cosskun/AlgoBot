import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/services/daily_challenge_service.dart';

void main() {
  group('DailyChallengeService Unit Tests', () {
    test('Star chests configuration is valid and progressive', () {
      final chests = DailyChallengeService.chests;
      expect(chests.length, equals(4));

      for (int i = 0; i < chests.length - 1; i++) {
        expect(
          chests[i].requiredStars,
          lessThan(chests[i + 1].requiredStars),
          reason: 'Each subsequent chest must require more stars than the previous',
        );
      }
    });

    test('getDailyChallengeLevel produces valid level data', () {
      final level = DailyChallengeService.instance.getDailyChallengeLevel();
      expect(level.cols, greaterThanOrEqualTo(3));
      expect(level.rows, greaterThanOrEqualTo(3));
      expect(level.allowedBlocks.isNotEmpty, isTrue);
      expect(level.robotStart, isNotNull);
      expect(level.goal, isNotNull);
    });

    test('todayKey is formatted correctly (YYYY-MM-DD)', () {
      final key = DailyChallengeService.instance.todayKey;
      final parts = key.split('-');
      expect(parts.length, equals(3));
      expect(parts[0].length, equals(4));
      expect(parts[1].length, equals(2));
      expect(parts[2].length, equals(2));
    });
  });
}
