import '../models/command_block.dart';
import '../models/level_data.dart';

class OptimalSolution {
  final List<CommandBlock> mainBlocks;
  final List<CommandBlock> f1Blocks;

  const OptimalSolution({
    required this.mainBlocks,
    this.f1Blocks = const [],
  });
}

class _SearchState {
  final int x;
  final int y;
  final bool hasKey;
  final int starsMask;

  _SearchState(this.x, this.y, this.hasKey, this.starsMask);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SearchState &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          hasKey == other.hasKey &&
          starsMask == other.starsMask;

  @override
  int get hashCode => Object.hash(x, y, hasKey, starsMask);
}

class SolutionSolver {
  /// Herhangi bir seviye için 3 yıldızlı en optimal, gerçek ve doğrulanmış komut dizilimini üretir.
  static OptimalSolution solve(LevelData level) {
    // 1. Durum uzayı BFS ile garantili en kısa yıldız + anahtar + hedef rotasını bul
    final points = _findFullPath(level);
    if (points.isEmpty) {
      return OptimalSolution(mainBlocks: [CommandBlock.forward()]);
    }

    // 2. Noktalar rotasını temel hareket bloklarına çevir
    final basicBlocks = _convertPointsToCommands(points, level.robotDir);

    // 3. Döngü sıkıştırması (Loop compression)
    List<CommandBlock> processedBlocks = basicBlocks;
    if (level.allowedBlocks.contains(CommandType.loopTimes)) {
      processedBlocks = _tryCompressWithLoops(basicBlocks);
    }

    // 4. Fonksiyon optimizasyonu (F1 function extraction)
    if (level.enableFunctionF1 && level.allowedBlocks.contains(CommandType.callF1)) {
      final f1Result = _tryExtractFunction(processedBlocks);
      if (f1Result != null) {
        return f1Result;
      }
    }

    return OptimalSolution(mainBlocks: processedBlocks);
  }

  /// State-space BFS: Bulmaca durum uzayında (pos, hasKey, starsMask) garantili tam çözüm
  static List<GridPoint> _findFullPath(LevelData level) {
    final start = level.robotStart;
    final goal = level.goal;
    final stars = level.stars;
    final obstacles = level.obstacles;
    final doors = level.doors;
    final keys = level.keys;

    final allStarsMask = (1 << stars.length) - 1;

    final queue = <_SearchState>[];
    final cameFrom = <_SearchState, _SearchState?>{};

    final initialKey = keys.isEmpty;
    int initialStarsMask = 0;
    for (int i = 0; i < stars.length; i++) {
      if (stars[i] == start) initialStarsMask |= (1 << i);
    }

    final startState = _SearchState(start.x, start.y, initialKey || keys.contains(start), initialStarsMask);
    queue.add(startState);
    cameFrom[startState] = null;

    _SearchState? endState;
    _SearchState? bestFallbackState;
    int maxStarsInFallback = -1;

    final deltas = [
      const GridPoint(0, -1),
      const GridPoint(1, 0),
      const GridPoint(0, 1),
      const GridPoint(-1, 0),
    ];

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);

      // Hedefe ulaşıldı ve tüm yıldızlar toplandı!
      if (curr.x == goal.x && curr.y == goal.y && curr.starsMask == allStarsMask) {
        endState = curr;
        break;
      }

      // En iyi fallback state (tüm yıldızlar toplanmasa bile hedefe ulaşılan durum)
      if (curr.x == goal.x && curr.y == goal.y) {
        int starsCount = 0;
        for (int i = 0; i < stars.length; i++) {
          if ((curr.starsMask & (1 << i)) != 0) starsCount++;
        }
        if (starsCount > maxStarsInFallback) {
          maxStarsInFallback = starsCount;
          bestFallbackState = curr;
        }
      }

      for (final d in deltas) {
        final nx = curr.x + d.x;
        final ny = curr.y + d.y;
        final nextPos = GridPoint(nx, ny);

        // Grid sınırları kontrolü
        if (nx < 0 || nx >= level.cols || ny < 0 || ny >= level.rows) continue;

        // Engel kontrolü
        if (obstacles.contains(nextPos)) continue;

        // Kilitli kapı ve anahtar kontrolü
        if (doors.contains(nextPos) && !curr.hasKey) continue;

        // Yıldızların tamamı toplanmadan erken bayrağa basılması oyunu erken bitirir
        if (nextPos == goal) {
          int nextStars = curr.starsMask;
          for (int i = 0; i < stars.length; i++) {
            if (stars[i] == nextPos) nextStars |= (1 << i);
          }
          if (nextStars != allStarsMask) {
            continue;
          }
        }

        final nextHasKey = curr.hasKey || keys.contains(nextPos);
        int nextStars = curr.starsMask;
        for (int i = 0; i < stars.length; i++) {
          if (stars[i] == nextPos) nextStars |= (1 << i);
        }

        final nextState = _SearchState(nx, ny, nextHasKey, nextStars);
        if (!cameFrom.containsKey(nextState)) {
          cameFrom[nextState] = curr;
          queue.add(nextState);
        }
      }
    }

    final targetState = endState ?? bestFallbackState;
    if (targetState == null) return [start, goal];

    final path = <GridPoint>[];
    _SearchState? curr = targetState;
    while (curr != null) {
      path.add(GridPoint(curr.x, curr.y));
      curr = cameFrom[curr];
    }
    return path.reversed.toList();
  }

  /// Koordinat dizisini yön dönüşleri ve ileri komutlarına dönüştürür
  static List<CommandBlock> _convertPointsToCommands(List<GridPoint> points, int initialDir) {
    final List<CommandBlock> blocks = [];
    int curDir = initialDir;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      int targetDir = curDir;
      if (p2.x > p1.x) {
        targetDir = 1; // Sağa
      } else if (p2.x < p1.x) {
        targetDir = 3; // Sola
      } else if (p2.y > p1.y) {
        targetDir = 2; // Aşağı
      } else if (p2.y < p1.y) {
        targetDir = 0; // Yukarı
      }

      while (curDir != targetDir) {
        final diff = (targetDir - curDir) % 4;
        if (diff == 1 || diff == -3) {
          blocks.add(CommandBlock.turnRight());
          curDir = (curDir + 1) % 4;
        } else {
          blocks.add(CommandBlock.turnLeft());
          curDir = (curDir + 3) % 4;
        }
      }

      blocks.add(CommandBlock.forward());
    }

    return blocks;
  }

  /// Akıllı döngü sıkıştırması: Tekrarlayan komut blok dizilerini loop bloğuna dönüştürür
  static List<CommandBlock> _tryCompressWithLoops(List<CommandBlock> blocks) {
    if (blocks.length < 2) return blocks;

    for (int patternLen = 4; patternLen >= 1; patternLen--) {
      for (int i = 0; i <= blocks.length - (patternLen * 2); i++) {
        final pattern = blocks.sublist(i, i + patternLen);
        if (pattern.any((b) => b.type == CommandType.loopTimes)) continue;

        int repeats = 1;
        while (i + (repeats + 1) * patternLen <= blocks.length && repeats < 5) {
          bool matches = true;
          for (int k = 0; k < patternLen; k++) {
            if (blocks[i + repeats * patternLen + k].type != pattern[k].type) {
              matches = false;
              break;
            }
          }
          if (matches) {
            repeats++;
          } else {
            break;
          }
        }

        if (repeats >= 2) {
          final compressed = <CommandBlock>[];
          compressed.addAll(blocks.sublist(0, i));
          compressed.add(CommandBlock.loop(
            times: repeats,
            children: pattern.map((b) => b.clone()).toList(),
          ));
          compressed.addAll(blocks.sublist(i + repeats * patternLen));
          return _tryCompressWithLoops(compressed);
        }
      }
    }

    return blocks;
  }

  /// Tekrarlayan kod kalıplarını F1 fonksiyonuna çıkarır
  static OptimalSolution? _tryExtractFunction(List<CommandBlock> blocks) {
    if (blocks.length < 4) return null;

    OptimalSolution? bestSolution;
    int bestTotalLength = blocks.length;

    for (int patternLen = 4; patternLen >= 2; patternLen--) {
      for (int i = 0; i <= blocks.length - patternLen; i++) {
        final candidate = blocks.sublist(i, i + patternLen);
        if (candidate.any((b) => b.type == CommandType.callF1)) continue;

        // Aday kalıbın kaç kez tekrar ettiğini ve F1 yapıldığında ne kadar kazandırdığını hesapla
        final replaced = <CommandBlock>[];
        int count = 0;
        int idx = 0;

        while (idx < blocks.length) {
          if (idx + patternLen <= blocks.length) {
            bool matches = true;
            for (int k = 0; k < patternLen; k++) {
              if (blocks[idx + k].type != candidate[k].type) {
                matches = false;
                break;
              }
            }
            if (matches) {
              replaced.add(CommandBlock.callF1());
              idx += patternLen;
              count++;
              continue;
            }
          }
          replaced.add(blocks[idx]);
          idx++;
        }

        if (count >= 2) {
          final totalLen = candidate.length + replaced.length;
          if (totalLen < bestTotalLength) {
            bestTotalLength = totalLen;
            bestSolution = OptimalSolution(
              f1Blocks: candidate.map((b) => b.clone()).toList(),
              mainBlocks: replaced,
            );
          }
        }
      }
    }

    return bestSolution;
  }
}
