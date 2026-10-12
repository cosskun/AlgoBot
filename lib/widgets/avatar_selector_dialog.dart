import 'package:flutter/material.dart';
import '../models/avatar_model.dart';

class AvatarSelectorDialog extends StatelessWidget {
  final String currentAvatarId;
  final Set<String> unlockedAvatarIds;
  final Function(AvatarModel selectedAvatar) onSelectAvatar;

  const AvatarSelectorDialog({
    super.key,
    required this.currentAvatarId,
    required this.unlockedAvatarIds,
    required this.onSelectAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Text('👗', style: TextStyle(fontSize: 26)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Robi Kostüm Dolabı',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2B2D42),
                          ),
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
            const SizedBox(height: 4),
            const Text(
              'Bölümleri tamamlayarak yeni avatarlar kazan ve istediğini seç!',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: AvatarModel.allAvatars.length,
                itemBuilder: (context, index) {
                  final avatar = AvatarModel.allAvatars[index];
                  final isUnlocked = unlockedAvatarIds.contains(avatar.id);
                  final isSelected = currentAvatarId == avatar.id;

                  return GestureDetector(
                    onTap: isUnlocked
                        ? () {
                            onSelectAvatar(avatar);
                            Navigator.pop(context);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? avatar.primaryColor.withAlpha(30)
                            : (isUnlocked ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? avatar.primaryColor
                              : (isUnlocked ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: avatar.primaryColor.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isUnlocked ? avatar.primaryColor : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    avatar.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              if (!isUnlocked)
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(100),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock, color: Colors.white, size: 24),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            avatar.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isUnlocked ? const Color(0xFF1E293B) : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUnlocked
                                ? (isSelected ? '✓ Giyildi' : 'Giy')
                                : avatar.requirement,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? avatar.primaryColor
                                  : (isUnlocked ? Colors.green : Colors.grey.shade600),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
