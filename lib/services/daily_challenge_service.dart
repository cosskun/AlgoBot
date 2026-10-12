import 'dart:math';
import '../models/command_block.dart';
import '../models/level_data.dart';
import 'locale_service.dart';
import 'storage_service.dart';

class StarChest {
  final String id;
  final String titleTr;
  final String titleEn;
  final int requiredStars;
  final String rewardAvatarId;
  final String emoji;
  final String rewardName;

  const StarChest({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.requiredStars,
    required this.rewardAvatarId,
    required this.emoji,
    required this.rewardName,
  });

  String getTitle(bool isEn) => isEn ? titleEn : titleTr;
}

class DailyChallengeService {
  DailyChallengeService._();
  static final DailyChallengeService instance = DailyChallengeService._();

  static const List<StarChest> chests = [
    StarChest(
      id: 'bronze_chest',
      titleTr: 'Bronz Hazine Sandığı',
      titleEn: 'Bronze Treasure Chest',
      requiredStars: 15,
      rewardAvatarId: 'climber_robi',
      emoji: '🥉 📦',
      rewardName: 'Dağcı Robi',
    ),
    StarChest(
      id: 'silver_chest',
      titleTr: 'Gümüş Yıldız Sandığı',
      titleEn: 'Silver Star Chest',
      requiredStars: 35,
      rewardAvatarId: 'turbo_robi',
      emoji: '🥈 🎁',
      rewardName: 'Turbo Robi',
    ),
    StarChest(
      id: 'gold_chest',
      titleTr: 'Altın Sihirli Sandık',
      titleEn: 'Golden Magic Chest',
      requiredStars: 60,
      rewardAvatarId: 'magic_robi',
      emoji: '🥇 ✨',
      rewardName: 'Büyücü Robi',
    ),
    StarChest(
      id: 'diamond_chest',
      titleTr: 'Efsanevi Elmas Sandık',
      titleEn: 'Legendary Diamond Chest',
      requiredStars: 90,
      rewardAvatarId: 'ninja_robi',
      emoji: '💎 👑',
      rewardName: 'Siber Ninja',
    ),
  ];

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool isTodayCompleted() {
    return StorageService.instance.isDailyChallengeCompleted(todayKey);
  }

  Future<void> markTodayCompleted() async {
    await StorageService.instance.markDailyChallengeCompleted(todayKey);
  }

  LevelData getDailyChallengeLevel({DateTime? overrideDate}) {
    final now = overrideDate ?? DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(daySeed);

    final isEn = LocaleService.instance.isEnglish;
    final title = isEn ? 'Daily Puzzle: $todayKey' : 'Günün Bulmacası: $todayKey';
    final story = isEn
        ? 'A mysterious daily algorithm challenge has appeared! Guide Robi to collect all stars and solve the maze.'
        : 'Bugünün özel gizemli algoritması belirdi! Robi\'yi yönlendir, yıldızları topla ve hedefe ulaş.';

    // Deterministic procedural generation
    final puzzleType = random.nextInt(4); // 0: Loop puzzle, 1: Key-Door puzzle, 2: Zigzag, 3: Obstacle avoidance

    if (puzzleType == 0) {
      // Loop puzzle (5x5)
      return LevelData(
        id: 9990,
        worldId: 1,
        title: title,
        story: story,
        hint: isEn ? 'Use loops to repeat pattern!' : 'Deseni tekrarlamak için Döngü kullan!',
        cols: 5,
        rows: 5,
        robotStart: const GridPoint(0, 4),
        robotDir: 0,
        goal: const GridPoint(4, 0),
        stars: const [GridPoint(0, 2), GridPoint(2, 2), GridPoint(2, 0), GridPoint(4, 0)],
        obstacles: const [GridPoint(1, 4), GridPoint(1, 3), GridPoint(3, 2), GridPoint(3, 1)],
        keys: const [],
        doors: const [],
        allowedBlocks: const [
          CommandType.forward,
          CommandType.turnRight,
          CommandType.turnLeft,
          CommandType.loopTimes,
        ],
        maxBlocksFor3Stars: 7,
      );
    } else if (puzzleType == 1) {
      // Key & Door puzzle
      return LevelData(
        id: 9990,
        worldId: 2,
        title: title,
        story: story,
        hint: isEn ? 'Fetch the key first to open the door!' : 'Önce anahtarı al, sonra kapıyı aç!',
        cols: 5,
        rows: 5,
        robotStart: const GridPoint(0, 0),
        robotDir: 1,
        goal: const GridPoint(4, 4),
        stars: const [GridPoint(2, 0), GridPoint(4, 2)],
        obstacles: const [GridPoint(1, 1), GridPoint(2, 1), GridPoint(3, 1), GridPoint(3, 3)],
        keys: const [GridPoint(4, 0)],
        doors: const [GridPoint(2, 2)],
        allowedBlocks: const [
          CommandType.forward,
          CommandType.turnRight,
          CommandType.turnLeft,
          CommandType.loopTimes,
        ],
        maxBlocksFor3Stars: 9,
      );
    } else if (puzzleType == 2) {
      // Zigzag Star Collector
      return LevelData(
        id: 9990,
        worldId: 3,
        title: title,
        story: story,
        hint: isEn ? 'Navigate through the zigzag corners.' : 'Zigzag köşeleri dikkatlice dön.',
        cols: 5,
        rows: 5,
        robotStart: const GridPoint(0, 0),
        robotDir: 1,
        goal: const GridPoint(4, 4),
        stars: const [GridPoint(3, 0), GridPoint(3, 2), GridPoint(1, 2), GridPoint(1, 4)],
        obstacles: const [GridPoint(1, 1), GridPoint(2, 1), GridPoint(2, 3), GridPoint(3, 3)],
        keys: const [],
        doors: const [],
        allowedBlocks: const [
          CommandType.forward,
          CommandType.turnRight,
          CommandType.turnLeft,
          CommandType.loopTimes,
        ],
        maxBlocksFor3Stars: 10,
      );
    } else {
      // Logic & Function / Obstacle
      return LevelData(
        id: 9990,
        worldId: 4,
        title: title,
        story: story,
        hint: isEn ? 'Watch out for obstacles on your path!' : 'Yolundaki engellere dikkat et!',
        cols: 5,
        rows: 5,
        robotStart: const GridPoint(2, 4),
        robotDir: 0,
        goal: const GridPoint(2, 0),
        obstacles: const [GridPoint(0, 2), GridPoint(1, 2), GridPoint(3, 2), GridPoint(4, 2)],
        keys: const [GridPoint(0, 4)],
        doors: const [GridPoint(2, 2)],
        stars: const [GridPoint(4, 4), GridPoint(0, 0), GridPoint(4, 0)],
        allowedBlocks: const [
          CommandType.forward,
          CommandType.turnRight,
          CommandType.turnLeft,
          CommandType.loopTimes,
        ],
        maxBlocksFor3Stars: 18,
      );
    }
  }
}
