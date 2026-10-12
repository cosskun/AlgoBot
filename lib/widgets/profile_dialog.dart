import 'package:flutter/material.dart';
import '../models/age_mode.dart';
import '../models/avatar_model.dart';
import '../models/sticker_model.dart';

class ProfileDialog extends StatelessWidget {
  final int unlockedLevelId;
  final int totalStars;
  final AvatarModel currentAvatar;
  final AgeMode? currentAgeMode;
  final VoidCallback? onChangeAgeMode;

  const ProfileDialog({
    super.key,
    required this.unlockedLevelId,
    required this.totalStars,
    required this.currentAvatar,
    this.currentAgeMode,
    this.onChangeAgeMode,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedStickersCount = StickerModel.allStickers.where((s) => unlockedLevelId >= s.unlockLevel).length;

    // Pedagojik Beceri Kazanım Hesaplamaları (100 Seviye İçin)
    final double seqMastery = (unlockedLevelId / 20).clamp(0.0, 1.0);
    final double loopMastery = ((unlockedLevelId - 20) / 20).clamp(0.0, 1.0);
    final double condMastery = ((unlockedLevelId - 50) / 10).clamp(0.0, 1.0);
    final double funcMastery = ((unlockedLevelId - 60) / 20).clamp(0.0, 1.0);
    final double debugMastery = ((unlockedLevelId - 80) / 20).clamp(0.0, 1.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Profil Başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: currentAvatar.primaryColor.withAlpha(40),
                            shape: BoxShape.circle,
                            border: Border.all(color: currentAvatar.primaryColor, width: 2),
                          ),
                          child: Center(
                            child: Text(currentAvatar.emoji, style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentAvatar.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                              ),
                              const Text(
                                'Gelişim Raporu & Profil',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
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
              const SizedBox(height: 16),

              // Özet İstatistik Kartları (3 Kutucuk)
              Row(
                children: [
                  _buildStatCard('Bölüm', '$unlockedLevelId / 100', '🚩', const Color(0xFF4361EE)),
                  const SizedBox(width: 8),
                  _buildStatCard('Yıldız', '$totalStars ⭐', '✨', const Color(0xFFFFB300)),
                  const SizedBox(width: 8),
                  _buildStatCard('Çıkartma', '$unlockedStickersCount / 20', '🏆', const Color(0xFFE91E63)),
                ],
              ),
              const SizedBox(height: 20),

              // Pedagojik Kazanımlar Bölümü
              const Text(
                '🧠 Pedagojik Beceri Karnesi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2B2D42)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Çocuğun algoritmik düşünme alanlarındaki gelişimi:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              _buildSkillBar('Sıralı Kodlama (Sequencing)', seqMastery, const Color(0xFF4361EE)),
              _buildSkillBar('Döngü Mantığı (Loops)', loopMastery, const Color(0xFFFF9F1C)),
              _buildSkillBar('Koşullu Kararlar (If / Else)', condMastery, const Color(0xFF10B981)),
              _buildSkillBar('Modüler Fonksiyonlar (F1)', funcMastery, const Color(0xFF8B5CF6)),
              _buildSkillBar('Hata Ayıklama (Debugging)', debugMastery, const Color(0xFFEC4899)),

              if (onChangeAgeMode != null && currentAgeMode != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onChangeAgeMode!();
                    },
                    icon: Text(currentAgeMode!.emoji, style: const TextStyle(fontSize: 18)),
                    label: Text(
                      'Yaş Grubunu Değiştir (${currentAgeMode!.title})',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: currentAgeMode!.color, width: 1.5),
                      foregroundColor: currentAgeMode!.color,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Ebeveyn Bilgilendirme Notu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ebeveyn Notu: Oyun çocukların adım adım neden-sonuç kurmasını, örüntüleri fark etmesini ve problem çözme azmini geliştirir.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBar(String title, double percentage, Color color) {
    final int percentInt = (percentage * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '%$percentInt',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
