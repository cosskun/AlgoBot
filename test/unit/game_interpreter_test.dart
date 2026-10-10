import 'package:flutter_test/flutter_test.dart';
import 'package:algobot_flutter/models/command_block.dart';
import 'package:algobot_flutter/services/game_interpreter.dart';

void main() {
  group('GameInterpreter Unit Tests', () {
    late GameInterpreter interpreter;

    setUp(() {
      interpreter = GameInterpreter();
    });

    test('Initial state is idle', () {
      expect(interpreter.isRunning, isFalse);
      expect(interpreter.isStepMode, isFalse);
      expect(interpreter.hasNextStep, isFalse);
    });

    test('Prepare step mode initializes call stack', () {
      final blocks = [CommandBlock.forward(), CommandBlock.turnRight()];
      interpreter.prepareStepMode(mainBlocks: blocks, f1Blocks: []);

      expect(interpreter.isStepMode, isTrue);
      expect(interpreter.hasNextStep, isTrue);
    });

    test('Execute single step executes sequentially and reports highlighted block', () async {
      final block1 = CommandBlock.forward();
      final block2 = CommandBlock.turnRight();
      final blocks = [block1, block2];

      interpreter.prepareStepMode(mainBlocks: blocks, f1Blocks: []);

      final executedActions = <String>[];
      final highlightedIds = <String?>[];

      // Step 1
      final res1 = await interpreter.executeSingleStep(
        onExecuteAction: (action) async {
          executedActions.add(action);
          return const StepResult(success: true);
        },
        onHighlightBlock: (id) => highlightedIds.add(id),
      );

      expect(res1?.success, isTrue);
      expect(executedActions, equals(['forward']));
      expect(highlightedIds.last, equals(block1.id));
      expect(interpreter.hasNextStep, isTrue);

      // Step 2
      final res2 = await interpreter.executeSingleStep(
        onExecuteAction: (action) async {
          executedActions.add(action);
          return const StepResult(success: true);
        },
        onHighlightBlock: (id) => highlightedIds.add(id),
      );

      expect(res2?.success, isTrue);
      expect(executedActions, equals(['forward', 'turn_right']));
      expect(highlightedIds.last, equals(block2.id));
      expect(interpreter.hasNextStep, isFalse);
    });

    test('Stop clears state and halts execution', () {
      final blocks = [CommandBlock.forward()];
      interpreter.prepareStepMode(mainBlocks: blocks, f1Blocks: []);
      expect(interpreter.hasNextStep, isTrue);

      interpreter.stop();
      expect(interpreter.isRunning, isFalse);
      expect(interpreter.isStepMode, isFalse);
      expect(interpreter.hasNextStep, isFalse);
    });
  });
}
