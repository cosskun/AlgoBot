import 'package:flutter/material.dart';
import '../models/sticker_model.dart';

class StickerAlbumDialog extends StatelessWidget {
  final int unlockedLevelId;

  const StickerAlbumDialog({
    super.key,
    required this.unlockedLevelId,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedCount = StickerModel.allStickers.where((s) => unlockedLevelId >= s.unlockLevel).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Çıkartma Albümü',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2B2D42),
                              ),
                            ),
                            Text(
                              '$unlockedCount / ${StickerModel.allStickers.length} Toplandı',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Her 10 bölümde bir yeni bir dijital çıkartma kazanırsın!',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: StickerModel.allStickers.length,
                itemBuilder: (context, index) {
                  final sticker = StickerModel.allStickers[index];
                  final isUnlocked = unlockedLevelId >= sticker.unlockLevel;

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? sticker.color.withAlpha(25)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked ? sticker.color : const Color(0xFFCBD5E1),
                        width: isUnlocked ? 2 : 1,
                      ),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: sticker.color.withAlpha(50),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isUnlocked ? sticker.color.withAlpha(40) : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isUnlocked
                                ? Text(sticker.emoji, style: const TextStyle(fontSize: 22))
                                : const Icon(Icons.lock, size: 20, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isUnlocked ? sticker.title : '${sticker.unlockLevel}. Bölüm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isUnlocked ? const Color(0xFF1E293B) : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
