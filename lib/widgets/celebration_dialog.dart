import 'package:flutter/material.dart';
import '../models/avatar_model.dart';

class CelebrationDialog extends StatelessWidget {
  final int starsEarned;
  final int blocksUsed;
  final int maxBlocksFor3Stars;
  final AvatarModel? newlyUnlockedAvatar;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback? onWatchSolution;
  final Function(AvatarModel avatar)? onEquipAvatar;

  const CelebrationDialog({
    super.key,
    required this.starsEarned,
    required this.blocksUsed,
    required this.maxBlocksFor3Stars,
    this.newlyUnlockedAvatar,
    required this.onNextLevel,
    required this.onReplay,
    this.onWatchSolution,
    this.onEquipAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFullStars = (starsEarned >= 3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            const Text(
              'Bölüm Tamamlandı!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B2D42),
              ),
            ),
            const SizedBox(height: 10),

            // Yıldızlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isEarned = index < starsEarned;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    isEarned ? '⭐' : '⚪',
                    style: const TextStyle(fontSize: 32),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Yıldız Kazanım Detay Kartı (Neden 2 veya 3 yıldız alındığını açıklar)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildStarRow(
                    isEarned: true,
                    title: '1. Yıldız: Hedefe Ulaşma',
                    detail: 'Robi başarıyla bayrağa vardı.',
                  ),
                  const Divider(height: 12, color: Color(0xFFE2E8F0)),
                  _buildStarRow(
                    isEarned: starsEarned >= 2,
                    title: '2. Yıldız: Görevleri Tamamlama',
                    detail: 'Yol üzerindeki yıldızları topladın.',
                  ),
                  const Divider(height: 12, color: Color(0xFFE2E8F0)),
                  _buildStarRow(
                    isEarned: isFullStars,
                    title: '3. Yıldız: En Verimli Algoritma',
                    detail: isFullStars
                        ? 'Harika! $blocksUsed blok ile en az adım hedefini ($maxBlocksFor3Stars) tutturdun! 🏆'
                        : 'Hedef: En fazla $maxBlocksFor3Stars blok (Sen $blocksUsed blok kullandın).',
                  ),
                ],
              ),
            ),

            // Yeni Avatar Açıldıysa Göster
            if (newlyUnlockedAvatar != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: newlyUnlockedAvatar!.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          newlyUnlockedAvatar!.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YENİ AVATAR HEDİYESİ!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          Text(
                            newlyUnlockedAvatar!.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onEquipAvatar != null)
                      ElevatedButton(
                        onPressed: () {
                          onEquipAvatar!(newlyUnlockedAvatar!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Giy', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Eğer 3 yıldız alınamadıysa:  3 Yıldızlı İdeal Çözümü İzle Butonu
            if (!isFullStars && onWatchSolution != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onWatchSolution!();
                  },
                  icon: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 20),
                  label: Text(
                    '💡 3 Yıldızlı İdeal Çözümü İzle ($maxBlocksFor3Stars Blok)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Tekrar Dene ve Sonraki Bölüm Butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onReplay();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 2),
                    ),
                    child: const Text(
                      '↺ Tekrar',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onNextLevel();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06D6A0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Sonraki Bölüm ➔',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRow({
    required bool isEarned,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isEarned ? '⭐' : '⚪', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isEarned ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isEarned ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        Icon(
          isEarned ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: isEarned ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
      ],
    );
  }
}
