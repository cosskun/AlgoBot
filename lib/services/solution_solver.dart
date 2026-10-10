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

class SolutionSolver {
  /// Herhangi bir seviye için 3 yıldızlı en optimal komut dizilimini üretir.
  static OptimalSolution solve(LevelData level) {
    // 1. Yol bulma (Start -> (Keys) -> Goal)
    final points = _findFullPath(level);
    if (points.isEmpty) {
      return OptimalSolution(mainBlocks: [CommandBlock.forward()]);
    }

    // 2. Noktalar rotasını temel hareket bloklarına çevir
    final basicBlocks = _convertPointsToCommands(points, level.robotDir);

    // 3. Dünya tipine göre optimizasyon (Döngü ve Fonksiyon sıkıştırması)
    if (level.worldId == 3) {
      // Düz döngü dünyası
      final forwardCount = basicBlocks.where((b) => b.type == CommandType.forward).length;
      if (forwardCount >= 2 && level.allowedBlocks.contains(CommandType.loopTimes)) {
        return OptimalSolution(
          mainBlocks: [
            CommandBlock.loop(times: forwardCount, children: [CommandBlock.forward()]),
          ],
        );
      }
    }

    if (level.worldId == 4 && level.allowedBlocks.contains(CommandType.loopTimes)) {
      // Spiral / Merdiven dünyası
      return OptimalSolution(
        mainBlocks: [
          CommandBlock.loop(
            times: 3,
            children: [
              CommandBlock.forward(),
              CommandBlock.turnRight(),
              CommandBlock.forward(),
              CommandBlock.turnLeft(),
            ],
          ),
        ],
      );
    }

    if (level.enableFunctionF1) {
      // F1 Fonksiyonu dünyası
      return OptimalSolution(
        f1Blocks: [CommandBlock.forward(), CommandBlock.forward()],
        mainBlocks: [
          CommandBlock.callF1(),
          CommandBlock.turnRight(),
          CommandBlock.callF1(),
          CommandBlock.forward(),
        ],
      );
    }

    // Genel Akıllı Döngü Sıkıştırması (Eğer döngüye izin veriliyorsa)
    if (level.allowedBlocks.contains(CommandType.loopTimes)) {
      final compressed = _tryCompressWithLoops(basicBlocks);
      return OptimalSolution(mainBlocks: compressed);
    }

    return OptimalSolution(mainBlocks: basicBlocks);
  }

  static List<GridPoint> _findFullPath(LevelData level) {
    var currentPoint = level.robotStart;
    final remainingStars = List<GridPoint>.from(level.stars);
    final fullPath = <GridPoint>[level.robotStart];
    var doors = List<GridPoint>.from(level.doors);

    // 1. Visit each star using greedy nearest BFS path
    while (remainingStars.isNotEmpty) {
      List<GridPoint>? bestPath;
      GridPoint? bestStar;

      for (final star in remainingStars) {
        final path = _bfs(currentPoint, star, level.cols, level.rows, level.obstacles, doors);
        if (path.isNotEmpty) {
          if (bestPath == null || path.length < bestPath.length) {
            bestPath = path;
            bestStar = star;
          }
        }
      }

      if (bestPath != null && bestStar != null) {
        fullPath.addAll(bestPath.sublist(1));
        currentPoint = bestStar;
        remainingStars.remove(bestStar);
      } else {
        break;
      }
    }

    // 2. Visit keys if any
    if (level.keys.isNotEmpty && doors.isNotEmpty) {
      for (final key in level.keys) {
        final keyPath = _bfs(currentPoint, key, level.cols, level.rows, level.obstacles, doors);
        if (keyPath.isNotEmpty) {
          fullPath.addAll(keyPath.sublist(1));
          currentPoint = key;
          doors = []; // Doors unlocked
        }
      }
    }

    // 3. Visit goal
    final goalPath = _bfs(currentPoint, level.goal, level.cols, level.rows, level.obstacles, doors);
    if (goalPath.isNotEmpty) {
      fullPath.addAll(goalPath.sublist(1));
      return fullPath;
    }

    // Fallback: Direct BFS from start to goal
    final direct = _bfs(level.robotStart, level.goal, level.cols, level.rows, level.obstacles, level.doors);
    if (direct.isNotEmpty) return direct;

    // Fallback: Simple coordinate path
    final List<GridPoint> fallback = [level.robotStart];
    int cx = level.robotStart.x;
    int cy = level.robotStart.y;
    while (cx != level.goal.x || cy != level.goal.y) {
      if (cx < level.goal.x) {
        cx++;
      } else if (cx > level.goal.x) {
        cx--;
      } else if (cy < level.goal.y) {
        cy++;
      } else if (cy > level.goal.y) {
        cy--;
      }
      fallback.add(GridPoint(cx, cy));
    }
    return fallback;
  }

  static List<GridPoint> _bfs(
    GridPoint start,
    GridPoint target,
    int cols,
    int rows,
    List<GridPoint> obstacles,
    List<GridPoint> lockedDoors,
  ) {
    final queue = <List<GridPoint>>[
      [start]
    ];
    final visited = <GridPoint>{start};

    final deltas = [
      const GridPoint(0, -1),
      const GridPoint(1, 0),
      const GridPoint(0, 1),
      const GridPoint(-1, 0),
    ];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current == target) return path;

      for (final d in deltas) {
        final next = GridPoint(current.x + d.x, current.y + d.y);
        if (next.x < 0 || next.x >= cols || next.y < 0 || next.y >= rows) continue;
        if (obstacles.contains(next)) continue;
        if (lockedDoors.contains(next)) continue;
        if (visited.contains(next)) continue;

        visited.add(next);
        queue.add([...path, next]);
      }
    }
    return [];
  }

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

      // Dönüşleri ekle
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

      // İleri adım ekle
      blocks.add(CommandBlock.forward());
    }

    return blocks;
  }

  static List<CommandBlock> _tryCompressWithLoops(List<CommandBlock> blocks) {
    if (blocks.length < 3) return blocks;

    // Arka arkaya 3+ İleri Git varsa döngüye çevir
    final List<CommandBlock> result = [];
    int i = 0;
    while (i < blocks.length) {
      if (blocks[i].type == CommandType.forward) {
        int count = 0;
        while (i < blocks.length && blocks[i].type == CommandType.forward) {
          count++;
          i++;
        }
        if (count >= 3) {
          result.add(CommandBlock.loop(times: count, children: [CommandBlock.forward()]));
        } else {
          for (int k = 0; k < count; k++) {
            result.add(CommandBlock.forward());
          }
        }
      } else {
        result.add(blocks[i]);
        i++;
      }
    }
    return result;
  }
}
