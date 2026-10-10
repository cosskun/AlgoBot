import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/models/command_block.dart';
import 'package:algobot_flutter/core/app_colors.dart';

void main() {
  group('CommandBlock Unit Tests', () {
    test('CommandBlock creates correct default types and colors', () {
      final fwd = CommandBlock.forward();
      expect(fwd.type, equals(CommandType.forward));
      expect(fwd.color, equals(AppColors.cmdForward));

      final turnR = CommandBlock.turnRight();
      expect(turnR.type, equals(CommandType.turnRight));
      expect(turnR.color, equals(AppColors.cmdTurnRight));

      final turnL = CommandBlock.turnLeft();
      expect(turnL.type, equals(CommandType.turnLeft));
      expect(turnL.color, equals(AppColors.cmdTurnLeft));

      final loop = CommandBlock.loop(times: 4);
      expect(loop.type, equals(CommandType.loopTimes));
      expect(loop.loopTimes, equals(4));
      expect(loop.color, equals(AppColors.cmdLoop));

      final f1 = CommandBlock.callF1();
      expect(f1.type, equals(CommandType.callF1));
      expect(f1.color, equals(AppColors.cmdFunction));

      final ifObs = CommandBlock.ifObstacle();
      expect(ifObs.type, equals(CommandType.ifObstacle));
      expect(ifObs.color, equals(AppColors.cmdCondition));
    });

    test('CommandBlock JSON serialization and deserialization preserves structure', () {
      final parentLoop = CommandBlock.loop(
        times: 3,
        children: [
          CommandBlock.forward(),
          CommandBlock.turnRight(),
        ],
      );

      final json = parentLoop.toJson();
      final restored = CommandBlock.fromJson(json);

      expect(restored.type, equals(CommandType.loopTimes));
      expect(restored.loopTimes, equals(3));
      expect(restored.children.length, equals(2));
      expect(restored.children[0].type, equals(CommandType.forward));
      expect(restored.children[1].type, equals(CommandType.turnRight));
    });

    test('CommandBlock deep clone creates independent objects', () {
      final original = CommandBlock.loop(
        times: 2,
        children: [CommandBlock.forward()],
      );

      final cloned = original.clone();
      expect(cloned.id, isNot(equals(original.id)));
      expect(cloned.children.length, equals(1));
      expect(cloned.children.first.id, isNot(equals(original.children.first.id)));

      // Modifying cloned child does not affect original
      cloned.children.add(CommandBlock.turnLeft());
      expect(original.children.length, equals(1));
      expect(cloned.children.length, equals(2));
    });
  });
}
