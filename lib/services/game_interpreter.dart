import 'dart:async';
import '../core/app_constants.dart';
import '../models/command_block.dart';
import '../models/level_data.dart';
import 'locale_service.dart';

class StepResult {
  final bool success;
  final bool reachedGoal;
  final String? reason;

  const StepResult({
    required this.success,
    this.reachedGoal = false,
    this.reason,
  });
}

class _StackFrame {
  final List<CommandBlock> blocks;
  int blockIndex;
  int currentLoopIteration;
  int totalLoopIterations;

  _StackFrame({
    required this.blocks,
  })  : blockIndex = 0,
        currentLoopIteration = 0,
        totalLoopIterations = 1;
}

class GameInterpreter {
  bool isRunning = false;
  bool isStepMode = false;
  bool _stopRequested = false;
  int stepDelayMs = AppConstants.defaultStepDelayMs;

  final List<_StackFrame> _callStack = [];
  List<CommandBlock> _f1Blocks = [];
  int _stepCounter = 0;
  static const int maxSteps = AppConstants.maxExecutionSteps;

  void setSpeed(String speed) {
    if (speed == 'slow') {
      stepDelayMs = AppConstants.slowStepDelayMs;
    } else if (speed == 'fast') {
      stepDelayMs = AppConstants.fastStepDelayMs;
    } else {
      stepDelayMs = AppConstants.defaultStepDelayMs;
    }
  }

  void stop() {
    _stopRequested = true;
    isRunning = false;
    isStepMode = false;
    _callStack.clear();
  }

  /// Initializes Step-by-Step (Debugger) mode
  void prepareStepMode({
    required List<CommandBlock> mainBlocks,
    required List<CommandBlock> f1Blocks,
  }) {
    stop();
    isStepMode = true;
    _stopRequested = false;
    _stepCounter = 0;
    _f1Blocks = f1Blocks;
    _callStack.clear();
    if (mainBlocks.isNotEmpty) {
      _callStack.add(_StackFrame(blocks: mainBlocks));
    }
  }

  bool get hasNextStep {
    if (!isStepMode || _callStack.isEmpty) return false;
    for (final frame in _callStack) {
      if (frame.blockIndex < frame.blocks.length) return true;
    }
    return false;
  }

  /// Executes a single atomic step in Step-by-Step mode
  Future<StepResult?> executeSingleStep({
    required Future<StepResult> Function(String action) onExecuteAction,
    required void Function(String? activeBlockId) onHighlightBlock,
  }) async {
    if (!isStepMode || _callStack.isEmpty) {
      onHighlightBlock(null);
      return null;
    }

    if (_stepCounter++ > maxSteps) {
      stop();
      onHighlightBlock(null);
      final isEn = LocaleService.instance.isEnglish;
      return StepResult(
        success: false,
        reason: isEn ? 'Step limit reached! Possible infinite loop.' : 'Adım sınırı aşıldı! Sonsuz döngü olabilir.',
      );
    }

    final top = _callStack.last;
    if (top.blockIndex >= top.blocks.length) {
      // Finished current frame
      _callStack.removeLast();
      if (_callStack.isNotEmpty) {
        final parent = _callStack.last;
        final currentBlock = parent.blocks[parent.blockIndex];
        if (currentBlock.type == CommandType.loopTimes) {
          parent.currentLoopIteration++;
          if (parent.currentLoopIteration < parent.totalLoopIterations) {
            // Repeat loop body
            _callStack.add(_StackFrame(blocks: currentBlock.children));
            return executeSingleStep(
              onExecuteAction: onExecuteAction,
              onHighlightBlock: onHighlightBlock,
            );
          } else {
            parent.blockIndex++;
            return executeSingleStep(
              onExecuteAction: onExecuteAction,
              onHighlightBlock: onHighlightBlock,
            );
          }
        } else {
          parent.blockIndex++;
          return executeSingleStep(
            onExecuteAction: onExecuteAction,
            onHighlightBlock: onHighlightBlock,
          );
        }
      } else {
        onHighlightBlock(null);
        return const StepResult(success: true);
      }
    }

    final block = top.blocks[top.blockIndex];
    onHighlightBlock(block.id);

    StepResult res;
    switch (block.type) {
      case CommandType.forward:
        res = await onExecuteAction('forward');
        top.blockIndex++;
        break;
      case CommandType.turnRight:
        res = await onExecuteAction('turn_right');
        top.blockIndex++;
        break;
      case CommandType.turnLeft:
        res = await onExecuteAction('turn_left');
        top.blockIndex++;
        break;
      case CommandType.loopTimes:
        top.totalLoopIterations = block.loopTimes;
        top.currentLoopIteration = 0;
        if (block.children.isNotEmpty && block.loopTimes > 0) {
          _callStack.add(_StackFrame(blocks: block.children));
          return const StepResult(success: true);
        } else {
          top.blockIndex++;
          return const StepResult(success: true);
        }
      case CommandType.ifObstacle:
        final obsRes = await onExecuteAction('check_obstacle');
        if (obsRes.success && block.thenChildren.isNotEmpty) {
          top.blockIndex++;
          _callStack.add(_StackFrame(blocks: block.thenChildren));
          return const StepResult(success: true);
        } else {
          top.blockIndex++;
          return const StepResult(success: true);
        }
      case CommandType.callF1:
        top.blockIndex++;
        if (_f1Blocks.isNotEmpty) {
          _callStack.add(_StackFrame(blocks: _f1Blocks));
          return const StepResult(success: true);
        } else {
          return const StepResult(success: true);
        }
    }

    if (!res.success || res.reachedGoal) {
      stop();
      onHighlightBlock(null);
    }
    return res;
  }

  /// Full Continuous Run
  Future<void> run({
    required List<CommandBlock> mainBlocks,
    required List<CommandBlock> f1Blocks,
    required LevelData level,
    required GridPoint currentRobotPos,
    required int currentRobotDir,
    required bool hasKey,
    required List<GridPoint> remainingStars,
    required List<GridPoint> openedDoors,
    required Future<StepResult> Function(String action) onExecuteAction,
    required void Function(String? activeBlockId) onHighlightBlock,
    required void Function(bool success, int starsCollected, String? reason) onComplete,
  }) async {
    if (isRunning) return;
    isRunning = true;
    isStepMode = false;
    _stopRequested = false;

    int stepCounter = 0;

    Future<StepResult> executeBlockList(List<CommandBlock> blocks) async {
      for (final block in blocks) {
        if (_stopRequested) return const StepResult(success: false);

        stepCounter++;
        if (stepCounter > maxSteps) {
          final isEn = LocaleService.instance.isEnglish;
          return StepResult(
            success: false,
            reason: isEn ? 'Step limit exceeded! Possible infinite loop.' : 'Komut sınırı aşıldı! Sonsuz döngü olabilir.',
          );
        }

        onHighlightBlock(block.id);

        StepResult res;
        switch (block.type) {
          case CommandType.forward:
            res = await onExecuteAction('forward');
            await Future.delayed(Duration(milliseconds: stepDelayMs));
            break;
          case CommandType.turnRight:
            res = await onExecuteAction('turn_right');
            await Future.delayed(Duration(milliseconds: stepDelayMs));
            break;
          case CommandType.turnLeft:
            res = await onExecuteAction('turn_left');
            await Future.delayed(Duration(milliseconds: stepDelayMs));
            break;
          case CommandType.loopTimes:
            res = const StepResult(success: true);
            for (int i = 0; i < block.loopTimes; i++) {
              if (_stopRequested) break;
              res = await executeBlockList(block.children);
              if (!res.success || res.reachedGoal) break;
            }
            break;
          case CommandType.ifObstacle:
            final obsRes = await onExecuteAction('check_obstacle');
            if (obsRes.success && block.thenChildren.isNotEmpty) {
              res = await executeBlockList(block.thenChildren);
            } else {
              res = const StepResult(success: true);
            }
            break;
          case CommandType.callF1:
            if (f1Blocks.isNotEmpty) {
              res = await executeBlockList(f1Blocks);
            } else {
              res = const StepResult(success: true);
            }
            break;
        }

        if (!res.success) return res;
        if (res.reachedGoal) return res;
      }
      return const StepResult(success: true);
    }

    final finalRes = await executeBlockList(mainBlocks);
    onHighlightBlock(null);
    isRunning = false;

    if (_stopRequested) return;

    final isEn = LocaleService.instance.isEnglish;
    if (finalRes.reachedGoal) {
      final starsCollected = level.stars.length - remainingStars.length;
      onComplete(true, starsCollected, null);
    } else if (!finalRes.success) {
      onComplete(false, 0, finalRes.reason ?? (isEn ? 'Robi hit an obstacle!' : 'Robi engelle karşılaştı!'));
    } else {
      onComplete(false, 0, isEn ? 'Commands ended but Robi hasn\'t reached the goal yet.' : 'Komutlar bitti ama Robi henüz hedefe ulaşamadı.');
    }
  }
}
