import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/models/command_block.dart';
import 'package:algobot_flutter/models/level_data.dart';
import 'package:algobot_flutter/services/solution_solver.dart';

void main() {
  group('SolutionSolver Unit Tests', () {
    test('Solves a simple 1-step straight level', () {
      const level = LevelData(
        id: 1,
        worldId: 1,
        title: 'Test Level 1',
        story: 'Go forward',
        hint: 'Hint',
        cols: 3,
        rows: 3,
        robotStart: GridPoint(1, 2),
        robotDir: 0,
        goal: GridPoint(1, 1),
        allowedBlocks: [CommandType.forward],
        maxBlocksFor3Stars: 1,
      );

      final solution = SolutionSolver.solve(level);
      expect(solution.mainBlocks.isNotEmpty, isTrue);
      expect(solution.mainBlocks.first.type, equals(CommandType.forward));
    });

    test('Solves a level with turning requirement', () {
      const level = LevelData(
        id: 2,
        worldId: 1,
        title: 'Turn Level',
        story: 'Turn and forward',
        hint: 'Hint',
        cols: 3,
        rows: 3,
        robotStart: GridPoint(0, 1),
        robotDir: 0,
        goal: GridPoint(1, 1),
        allowedBlocks: [CommandType.forward, CommandType.turnRight],
        maxBlocksFor3Stars: 2,
      );

      final solution = SolutionSolver.solve(level);
      expect(solution.mainBlocks.isNotEmpty, isTrue);
      final types = solution.mainBlocks.map((b) => b.type).toList();
      expect(types, contains(CommandType.turnRight));
      expect(types, contains(CommandType.forward));
    });

    test('All 100 levels have achievable 3-star maxBlocks threshold when collecting stars', () {
      final discrepancies = <String>[];
      for (final level in LevelData.allLevels) {
        final solution = SolutionSolver.solve(level);
        final totalBlocks = solution.mainBlocks.length + solution.f1Blocks.length;
        if (level.maxBlocksFor3Stars < totalBlocks) {
          discrepancies.add('Level ${level.id} (${level.title}): needs $totalBlocks, currently maxBlocksFor3Stars=${level.maxBlocksFor3Stars}');
        }
      }
      expect(discrepancies, isEmpty, reason: 'Every level must allow earning 3 stars when collecting all stars.');
    });
  });
}
