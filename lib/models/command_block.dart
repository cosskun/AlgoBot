import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/locale_service.dart';

enum CommandType {
  forward,
  turnRight,
  turnLeft,
  loopTimes,
  ifObstacle,
  callF1,
}

class CommandBlock {
  final String id;
  final CommandType type;
  int loopTimes; // 2, 3, 4, 5
  List<CommandBlock> children;
  List<CommandBlock> thenChildren;
  List<CommandBlock> elseChildren;

  CommandBlock({
    required this.id,
    required this.type,
    this.loopTimes = 3,
    List<CommandBlock>? children,
    List<CommandBlock>? thenChildren,
    List<CommandBlock>? elseChildren,
  })  : children = children ?? [],
        thenChildren = thenChildren ?? [],
        elseChildren = elseChildren ?? [];

  static int _idCounter = 0;
  static String _nextId() => 'cmd_${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}';

  factory CommandBlock.forward() => CommandBlock(
        id: _nextId(),
        type: CommandType.forward,
      );

  factory CommandBlock.turnRight() => CommandBlock(
        id: _nextId(),
        type: CommandType.turnRight,
      );

  factory CommandBlock.turnLeft() => CommandBlock(
        id: _nextId(),
        type: CommandType.turnLeft,
      );

  factory CommandBlock.loop({int times = 3, List<CommandBlock>? children}) => CommandBlock(
        id: _nextId(),
        type: CommandType.loopTimes,
        loopTimes: times,
        children: children,
      );

  factory CommandBlock.callF1() => CommandBlock(
        id: _nextId(),
        type: CommandType.callF1,
      );

  factory CommandBlock.ifObstacle({List<CommandBlock>? thenChildren, List<CommandBlock>? elseChildren}) => CommandBlock(
        id: _nextId(),
        type: CommandType.ifObstacle,
        thenChildren: thenChildren,
        elseChildren: elseChildren,
      );

  String get title {
    final isEn = LocaleService.instance.isEnglish;
    switch (type) {
      case CommandType.forward:
        return isEn ? 'Move Forward' : 'İleri Git';
      case CommandType.turnRight:
        return isEn ? 'Turn Right' : 'Sağa Dön';
      case CommandType.turnLeft:
        return isEn ? 'Turn Left' : 'Sola Dön';
      case CommandType.loopTimes:
        return isEn ? 'Repeat $loopTimes Times' : '$loopTimes Kez Tekrarla';
      case CommandType.ifObstacle:
        return isEn ? 'If Obstacle Ahead' : 'Eğer Engel Varsa';
      case CommandType.callF1:
        return isEn ? 'Magic F1' : 'Sihirli F1';
    }
  }

  String get iconEmoji {
    switch (type) {
      case CommandType.forward:
        return '⬆️';
      case CommandType.turnRight:
        return '↷';
      case CommandType.turnLeft:
        return '↶';
      case CommandType.loopTimes:
        return '🔄';
      case CommandType.ifObstacle:
        return '🔀';
      case CommandType.callF1:
        return '✨';
    }
  }

  Color get color {
    switch (type) {
      case CommandType.forward:
        return AppColors.cmdForward;
      case CommandType.turnRight:
        return AppColors.cmdTurnRight;
      case CommandType.turnLeft:
        return AppColors.cmdTurnLeft;
      case CommandType.loopTimes:
        return AppColors.cmdLoop;
      case CommandType.ifObstacle:
        return AppColors.cmdCondition;
      case CommandType.callF1:
        return AppColors.cmdFunction;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'loopTimes': loopTimes,
      'children': children.map((c) => c.toJson()).toList(),
      'thenChildren': thenChildren.map((c) => c.toJson()).toList(),
      'elseChildren': elseChildren.map((c) => c.toJson()).toList(),
    };
  }

  factory CommandBlock.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'forward';
    final type = CommandType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => CommandType.forward,
    );
    return CommandBlock(
      id: json['id'] as String? ?? _nextId(),
      type: type,
      loopTimes: json['loopTimes'] as int? ?? 3,
      children: (json['children'] as List?)?.map((c) => CommandBlock.fromJson(c as Map<String, dynamic>)).toList(),
      thenChildren: (json['thenChildren'] as List?)?.map((c) => CommandBlock.fromJson(c as Map<String, dynamic>)).toList(),
      elseChildren: (json['elseChildren'] as List?)?.map((c) => CommandBlock.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  CommandBlock clone() {
    return CommandBlock(
      id: '${DateTime.now().microsecondsSinceEpoch}_$id',
      type: type,
      loopTimes: loopTimes,
      children: children.map((c) => c.clone()).toList(),
      thenChildren: thenChildren.map((c) => c.clone()).toList(),
      elseChildren: elseChildren.map((c) => c.clone()).toList(),
    );
  }
}
