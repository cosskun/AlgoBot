import 'package:flutter/material.dart';
import '../models/command_block.dart';
import '../models/level_data.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';

class WorkspaceView extends StatelessWidget {
  final List<CommandBlock> blocks;
  final String? highlightedBlockId;
  final LevelData level;
  final Function(CommandBlock block) onDeleteBlock;
  final Function(CommandBlock parentBlock, CommandType childType) onAddChildBlock;
  final Function(int oldIndex, int newIndex)? onReorderBlocks;
  final Function(int insertIndex, CommandType type)? onInsertBlockAt;

  const WorkspaceView({
    super.key,
    required this.blocks,
    required this.highlightedBlockId,
    required this.level,
    required this.onDeleteBlock,
    required this.onAddChildBlock,
    this.onReorderBlocks,
    this.onInsertBlockAt,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleService.instance.isEnglish;

    if (blocks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          isEn
              ? 'Add command blocks here!\n(Tap from above drawer)'
              : 'Buraya komut blokları ekle!\n(Yukarıdaki çekmeceden tıkla)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: blocks.length,
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        SoundService.instance.playStep();
        if (onReorderBlocks != null) {
          onReorderBlocks!(oldIndex, newIndex);
        }
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 6,
          color: Colors.transparent,
          shadowColor: const Color(0xFF3B82F6).withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final block = blocks[index];
        return Container(
          key: ValueKey(block.id),
          child: Column(
            children: [
              _buildBlockItem(context, block, index + 1, index),
              if (onInsertBlockAt != null)
                _buildInlineInsertButton(context, index + 1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInlineInsertButton(BuildContext context, int insertIndex) {
    return Container(
      height: 18,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Center(
        child: InkWell(
          onTap: () => _showInsertBlockMenu(context, insertIndex),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline, size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  LocaleService.instance.tr('insertHere'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockItem(BuildContext context, CommandBlock block, int stepNum, int index) {
    final isHighlighted = (highlightedBlockId == block.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 4, top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
          width: isHighlighted ? 2.5 : 1.5,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withAlpha(120),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_indicator, size: 18, color: Color(0xFF94A3B8)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$stepNum',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 8),
              Text(block.iconEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: block.color,
                  ),
                ),
              ),
              if (block.type == CommandType.loopTimes) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF9800)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${block.loopTimes}x',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFF9800)),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          SoundService.instance.playBlockSnap();
                          block.loopTimes = (block.loopTimes >= 5) ? 2 : block.loopTimes + 1;
                          (context as Element).markNeedsBuild();
                        },
                        child: const Icon(Icons.tune, size: 14, color: Color(0xFFFF9800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                onPressed: () {
                  SoundService.instance.playBlockSnap();
                  onDeleteBlock(block);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // Döngü veya Koşul İç İçe Çocuk Blokları
          if (block.type == CommandType.loopTimes || block.type == CommandType.ifObstacle) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (block.children.isEmpty)
                    InkWell(
                      onTap: () => _showAddChildMenu(context, block),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBAE6FD), style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Text(
                            LocaleService.instance.isEnglish ? '+ Add child command' : '+ İçine komut ekle',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: block.children.asMap().entries.map((entry) {
                        final child = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(child.iconEmoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  child.title,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                                onPressed: () {
                                  SoundService.instance.playBlockSnap();
                                  block.children.removeAt(entry.key);
                                  onDeleteBlock(block);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showInsertBlockMenu(BuildContext context, int insertIndex) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.instance.isEnglish ? 'Insert Command Here' : 'Araya Komut Ekle',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: level.allowedBlocks.map((t) {
                  final dummy = CommandBlock(id: 'd', type: t);
                  return ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      SoundService.instance.playBlockSnap();
                      if (onInsertBlockAt != null) {
                        onInsertBlockAt!(insertIndex, t);
                      }
                    },
                    icon: Text(dummy.iconEmoji),
                    label: Text(dummy.title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dummy.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAddChildMenu(BuildContext context, CommandBlock parentBlock) {
    final baseBlocks = [
      CommandType.forward,
      CommandType.turnRight,
      CommandType.turnLeft,
    ];
    final childOptions = [
      ...baseBlocks,
      ...level.allowedBlocks.where((t) => t != CommandType.loopTimes && !baseBlocks.contains(t)),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.instance.isEnglish ? 'Add Command Inside Loop/If' : 'Döngü / Koşul İçine Komut Ekle',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: childOptions.map((t) {
                  final dummy = CommandBlock(id: 'd', type: t);
                  return ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      SoundService.instance.playBlockSnap();
                      onAddChildBlock(parentBlock, t);
                    },
                    icon: Text(dummy.iconEmoji),
                    label: Text(dummy.title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dummy.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
