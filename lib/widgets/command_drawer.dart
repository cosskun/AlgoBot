import 'package:flutter/material.dart';
import '../models/command_block.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';

class CommandDrawer extends StatelessWidget {
  final List<CommandType> allowedBlocks;
  final Function(CommandType type) onAddBlock;

  const CommandDrawer({
    super.key,
    required this.allowedBlocks,
    required this.onAddBlock,
  });

  @override
  Widget build(BuildContext context) {
    // Temel yön blokları her zaman görünür (İleri Git, Sağa Dön, Sola Dön)
    final baseBlocks = [
      CommandType.forward,
      CommandType.turnRight,
      CommandType.turnLeft,
    ];

    final displayBlocks = [
      ...baseBlocks,
      ...allowedBlocks.where((b) => !baseBlocks.contains(b)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleService.instance.tr('commandDrawer'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                LocaleService.instance.tr('tapToAdd'),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildBlockGrid(displayBlocks),
        ],
      ),
    );
  }

  Widget _buildBlockGrid(List<CommandType> displayBlocks) {
    if (displayBlocks.length <= 3) {
      return Row(
        children: displayBlocks.map((type) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _buildBlockButton(type),
            ),
          );
        }).toList(),
      );
    }

    // 4 veya daha fazla blok varsa ekrana tam sığacak şekilde 2 sıraya böl
    final mid = (displayBlocks.length / 2).ceil();
    final row1 = displayBlocks.sublist(0, mid);
    final row2 = displayBlocks.sublist(mid);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: row1.map((type) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _buildBlockButton(type),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: row2.map((type) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _buildBlockButton(type),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBlockButton(CommandType type) {
    final dummyBlock = CommandBlock(id: 'dummy', type: type);
    return Material(
      color: dummyBlock.color,
      borderRadius: BorderRadius.circular(10),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          SoundService.instance.playBlockSnap();
          onAddBlock(type);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dummyBlock.iconEmoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  dummyBlock.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 11, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
