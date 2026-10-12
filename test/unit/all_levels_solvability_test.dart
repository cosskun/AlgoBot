import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/models/command_block.dart';
import 'package:algobot_flutter/models/level_data.dart';
import 'package:algobot_flutter/services/daily_challenge_service.dart';

class _State {
  final int x;
  final int y;
  final bool hasKey;
  final int starsMask;

  _State(this.x, this.y, this.hasKey, this.starsMask);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _State &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          hasKey == other.hasKey &&
          starsMask == other.starsMask;

  @override
  int get hashCode => Object.hash(x, y, hasKey, starsMask);
}

List<GridPoint> findOptimalPath(LevelData level) {
  final start = level.robotStart;
  final goal = level.goal;
  final stars = level.stars;
  final obstacles = level.obstacles;
  final doors = level.doors;
  final keys = level.keys;

  final allStarsMask = (1 << stars.length) - 1;

  final queue = <_State>[];
  final cameFrom = <_State, _State?>{};

  final initialKey = keys.isEmpty;
  int initialStarsMask = 0;
  for (int i = 0; i < stars.length; i++) {
    if (stars[i] == start) initialStarsMask |= (1 << i);
  }

  final startState = _State(start.x, start.y, initialKey || keys.contains(start), initialStarsMask);
  queue.add(startState);
  cameFrom[startState] = null;

  _State? endState;

  final deltas = [
    const GridPoint(0, -1),
    const GridPoint(1, 0),
    const GridPoint(0, 1),
    const GridPoint(-1, 0),
  ];

  while (queue.isNotEmpty) {
    final curr = queue.removeAt(0);

    // Goal reached with all stars collected!
    if (curr.x == goal.x && curr.y == goal.y && curr.starsMask == allStarsMask) {
      endState = curr;
      break;
    }

    for (final d in deltas) {
      final nx = curr.x + d.x;
      final ny = curr.y + d.y;
      final nextPos = GridPoint(nx, ny);

      // Bounds
      if (nx < 0 || nx >= level.cols || ny < 0 || ny >= level.rows) continue;

      // Obstacle
      if (obstacles.contains(nextPos)) continue;

      // Door without key
      if (doors.contains(nextPos) && !curr.hasKey) continue;

      // Cannot prematurely step on goal if not all stars collected
      if (nextPos == goal) {
        int nextStars = curr.starsMask;
        for (int i = 0; i < stars.length; i++) {
          if (stars[i] == nextPos) nextStars |= (1 << i);
        }
        if (nextStars != allStarsMask) {
          continue; // Robi cannot step on goal before collecting all stars
        }
      }

      final nextHasKey = curr.hasKey || keys.contains(nextPos);
      int nextStars = curr.starsMask;
      for (int i = 0; i < stars.length; i++) {
        if (stars[i] == nextPos) nextStars |= (1 << i);
      }

      final nextState = _State(nx, ny, nextHasKey, nextStars);
      if (!cameFrom.containsKey(nextState)) {
        cameFrom[nextState] = curr;
        queue.add(nextState);
      }
    }
  }

  if (endState == null) return [start, goal];

  final path = <GridPoint>[];
  _State? curr = endState;
  while (curr != null) {
    path.add(GridPoint(curr.x, curr.y));
    curr = cameFrom[curr];
  }
  return path.reversed.toList();
}

List<CommandBlock> convertPointsToCommands(List<GridPoint> points, int initialDir) {
  final List<CommandBlock> blocks = [];
  int curDir = initialDir;

  for (int i = 0; i < points.length - 1; i++) {
    final p1 = points[i];
    final p2 = points[i + 1];

    int targetDir = curDir;
    if (p2.x > p1.x) {
      targetDir = 1; // Right
    } else if (p2.x < p1.x) {
      targetDir = 3; // Left
    } else if (p2.y > p1.y) {
      targetDir = 2; // Down
    } else if (p2.y < p1.y) {
      targetDir = 0; // Up
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

List<CommandBlock> compressLoops(List<CommandBlock> blocks) {
  if (blocks.length < 2) return blocks;

  // 1. Check for repeated patterns (length 1 to 4) repeated 2 to 5 times
  for (int patternLen = 4; patternLen >= 1; patternLen--) {
    for (int i = 0; i <= blocks.length - (patternLen * 2); i++) {
      final pattern = blocks.sublist(i, i + patternLen);
      // Skip if pattern already contains a loop
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
        return compressLoops(compressed);
      }
    }
  }

  return blocks;
}

/// Simulate execution of commands on a level
bool simulate(LevelData level, List<CommandBlock> mainBlocks, List<CommandBlock> f1Blocks) {
  var pos = level.robotStart;
  var dir = level.robotDir;
  var hasKey = level.keys.isEmpty;
  final remainingStars = Set<GridPoint>.from(level.stars);
  var reachedGoal = false;

  final deltas = [
    const GridPoint(0, -1),
    const GridPoint(1, 0),
    const GridPoint(0, 1),
    const GridPoint(-1, 0),
  ];

  bool stepForward() {
    final nextX = pos.x + deltas[dir].x;
    final nextY = pos.y + deltas[dir].y;
    final next = GridPoint(nextX, nextY);

    if (nextX < 0 || nextX >= level.cols || nextY < 0 || nextY >= level.rows) {
      return false; // Out of bounds
    }
    if (level.obstacles.contains(next)) {
      return false; // Hit obstacle
    }
    if (level.doors.contains(next) && !hasKey) {
      return false; // Locked door
    }

    pos = next;
    if (level.keys.contains(pos)) hasKey = true;
    remainingStars.remove(pos);
    if (pos == level.goal) reachedGoal = true;
    return true;
  }

  bool executeBlockList(List<CommandBlock> blocks) {
    for (final b in blocks) {
      if (reachedGoal) return true;
      switch (b.type) {
        case CommandType.forward:
          if (!stepForward()) return false;
          break;
        case CommandType.turnRight:
          dir = (dir + 1) % 4;
          break;
        case CommandType.turnLeft:
          dir = (dir + 3) % 4;
          break;
        case CommandType.loopTimes:
          for (int r = 0; r < b.loopTimes; r++) {
            if (!executeBlockList(b.children)) return false;
            if (reachedGoal) break;
          }
          break;
        case CommandType.callF1:
          if (!executeBlockList(f1Blocks)) return false;
          break;
        case CommandType.ifObstacle:
          break;
      }
    }
    return true;
  }

  final ok = executeBlockList(mainBlocks);
  return ok && reachedGoal && remainingStars.isEmpty;
}

void main() {
  test('Verify optimal solution simulation on all 100 levels + 4 daily puzzles', () {
    final failedLevels = <int>[];

    for (final level in LevelData.allLevels) {
      final points = findOptimalPath(level);
      final rawCommands = convertPointsToCommands(points, level.robotDir);
      final commands = level.allowedBlocks.contains(CommandType.loopTimes)
          ? compressLoops(rawCommands)
          : rawCommands;

      final success = simulate(level, commands, []);
      if (!success) {
        failedLevels.add(level.id);
      }
    }

    final daily = DailyChallengeService.instance;
    final failedDaily = <int>[];
    for (int day = 1; day <= 4; day++) {
      final level = daily.getDailyChallengeLevel(overrideDate: DateTime(2026, 1, day));
      final points = findOptimalPath(level);
      final rawCommands = convertPointsToCommands(points, level.robotDir);
      final commands = level.allowedBlocks.contains(CommandType.loopTimes)
          ? compressLoops(rawCommands)
          : rawCommands;

      final success = simulate(level, commands, []);
      if (!success) {
        failedDaily.add(day);
      }
    }

    expect(failedLevels, isEmpty, reason: 'Failed levels: $failedLevels');
    expect(failedDaily, isEmpty, reason: 'Failed daily puzzles: $failedDaily');
  });
}
