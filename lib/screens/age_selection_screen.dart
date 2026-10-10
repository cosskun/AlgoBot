import 'package:flutter/material.dart';
import '../models/age_mode.dart';
import '../models/avatar_model.dart';
import '../services/daily_challenge_service.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/avatar_selector_dialog.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/sticker_album_dialog.dart';
import 'game_screen.dart';
import 'sandbox_level_builder_screen.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _currentAvatarId = 'classic_robi';
  final Set<String> _unlockedAvatarIds = {'classic_robi'};
  final Map<int, int> _levelStars = {};

  AvatarModel get _currentAvatar =>
      AvatarModel.allAvatars.firstWhere((a) => a.id == _currentAvatarId, orElse: () => AvatarModel.allAvatars.first);

  int get _totalStars => _levelStars.values.fold(0, (sum, s) => sum + s);

  @override
  void initState() {
    super.initState();
    _refreshState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  void _refreshState() {
    final storage = StorageService.instance;
    _currentAvatarId = storage.avatarId;
    _unlockedAvatarIds.clear();
    _unlockedAvatarIds.addAll(storage.unlockedAvatars);
    _levelStars.clear();
    _levelStars.addAll(storage.levelStars);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startGame(AgeMode mode) async {
    SoundService.instance.playStep();
    await StorageService.instance.saveAgeMode(mode);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          initialAgeMode: mode,
          initialLevelIndex: 0,
        ),
      ),
    );
  }

  void _startDailyChallenge() {
    SoundService.instance.playStep();
    final dailyLevel = DailyChallengeService.instance.getDailyChallengeLevel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          initialAgeMode: AgeMode.explorer,
          customLevel: dailyLevel,
        ),
      ),
    ).then((_) {
      setState(() {
        _refreshState();
      });
    });
  }

  void _showMysteryChestsDialog() {
    SoundService.instance.playChestOpen();
    final isEn = LocaleService.instance.isEnglish;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Text(
                    isEn ? 'Star Mystery Chests' : 'Yıldız Sandıkları',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            isEn ? 'Total Stars: $_totalStars' : 'Toplam Yıldız: $_totalStars',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF92400E), fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: DailyChallengeService.chests.length,
                        itemBuilder: (context, idx) {
                          final chest = DailyChallengeService.chests[idx];
                          final isOpened = StorageService.instance.isChestOpened(chest.id) || _unlockedAvatarIds.contains(chest.rewardAvatarId);
                          final canOpen = _totalStars >= chest.requiredStars && !isOpened;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isOpened ? const Color(0xFFF1F5F9) : (canOpen ? const Color(0xFFECFDF5) : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isOpened
                                    ? const Color(0xFFCBD5E1)
                                    : (canOpen ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                                width: canOpen ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(chest.emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chest.getTitle(isEn),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                      Text(
                                        isOpened
                                            ? (isEn ? 'Unlocked: ${chest.rewardName} ✅' : 'Açıldı: ${chest.rewardName} ✅')
                                            : (isEn ? 'Requires ${chest.requiredStars} ⭐ (${chest.rewardName})' : '${chest.requiredStars} ⭐ Gerekli (${chest.rewardName})'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isOpened ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canOpen)
                                  ElevatedButton(
                                    onPressed: () async {
                                      SoundService.instance.playChestOpen();
                                      await StorageService.instance.openChest(chest.id);
                                      await StorageService.instance.unlockAvatar(chest.rewardAvatarId);
                                      setState(() {
                                        _refreshState();
                                      });
                                      setModalState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(isEn ? 'OPEN! 🎉' : 'AÇ! 🎉', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                  )
                                else if (isOpened)
                                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22)
                                else
                                  Text(
                                    '$_totalStars/${chest.requiredStars} ⭐',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF94A3B8)),
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
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4361EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEn ? 'Done' : 'Kapat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTopMenuBottomSheet() {
    final isEn = LocaleService.instance.isEnglish;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  isEn ? 'AlgoKids Menu' : 'AlgoKids Menü',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFF4361EE)),
                  ),
                  title: Text(
                    LocaleService.instance.tr('profile'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => ProfileDialog(
                        unlockedLevelId: _levelStars.length + 1,
                        totalStars: _totalStars,
                        currentAvatar: _currentAvatar,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFFFF9F1C)),
                  ),
                  title: Text(
                    LocaleService.instance.tr('stickers'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => StickerAlbumDialog(
                        unlockedLevelId: _levelStars.length + 1,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.draw_rounded, color: Color(0xFF10B981)),
                  ),
                  title: Text(
                    LocaleService.instance.tr('sandbox'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SandboxLevelBuilderScreen(avatar: _currentAvatar),
                      ),
                    ).then((_) {
                      setState(() {
                        _refreshState();
                      });
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDailyDone = DailyChallengeService.instance.isTodayCompleted();
    final isEn = LocaleService.instance.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Üst Menü
            _buildTopBar(),

            // Ana İçerik
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // --- UYGULAMA LOGOSU & ROBİ KAHRAMAN ALANI ---
                    _buildAppLogoBanner(),

                    const SizedBox(height: 10),

                    // --- GÜNÜN BULMACASI KARTI ---
                    _buildDailyChallengeCard(isDailyDone, isEn),

                    const SizedBox(height: 10),

                    // Başlık ve Yönerge
                    Text(
                      LocaleService.instance.tr('howOld'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.instance.tr('pickAge'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 1. Kart: 4-6 Yaş Mini Mod
                    _buildSimpleAgeCard(
                      emoji: '🐣',
                      ageText: '4–6 ${isEn ? "Years" : "Yaş"}',
                      title: 'Mini Mod',
                      subtitle: LocaleService.instance.tr('miniModSubtitle'),
                      color: const Color(0xFFFF9F1C),
                      onTap: () => _startGame(AgeMode.mini),
                    ),

                    const SizedBox(height: 10),

                    // 2. Kart: 7-9 Yaş Kaşif Modu
                    _buildSimpleAgeCard(
                      emoji: '🚀',
                      ageText: '7–9 ${isEn ? "Years" : "Yaş"}',
                      title: isEn ? 'Explorer Mode' : 'Kaşif Modu',
                      subtitle: LocaleService.instance.tr('explorerModSubtitle'),
                      color: const Color(0xFF4361EE),
                      onTap: () => _startGame(AgeMode.explorer),
                    ),

                    const SizedBox(height: 10),

                    // 3. Kart: 10+ Yaş Usta Modu
                    _buildSimpleAgeCard(
                      emoji: '🧠',
                      ageText: '10+ ${isEn ? "Years" : "Yaş"}',
                      title: isEn ? 'Master Coder' : 'Usta Kodlayıcı',
                      subtitle: LocaleService.instance.tr('masterModSubtitle'),
                      color: const Color(0xFF10B981),
                      onTap: () => _startGame(AgeMode.master),
                    ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(bool isDailyDone, bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDailyDone ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDailyDone ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDailyDone ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: Text(isDailyDone ? '🏆' : '🧩', style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      LocaleService.instance.tr('dailyChallenge'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDailyDone ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                      ),
                    ),
                    if (isDailyDone) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isEn ? 'DONE' : 'TAMAM',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isDailyDone
                      ? (isEn ? 'Completed today! New challenge tomorrow.' : 'Bugünkü tamamlandı! Yarın yenisi gelecek.')
                      : (isEn ? 'Solve today\'s puzzle & earn special stars!' : 'Günün özel bulmacasını çöz, yıldızları kap!'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _startDailyChallenge,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDailyDone ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isDailyDone ? (isEn ? 'Replay' : 'Tekrar') : (isEn ? 'PLAY' : 'ÇÖZ'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4361EE), Color(0xFF3F37C9)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🤖', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 6),
              const Text(
                'AlgoKids',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),

          // TR / EN Dil Butonu
          InkWell(
            onTap: () {
              LocaleService.instance.toggleLanguage();
              setState(() {});
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LocaleService.instance.languageEmoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text(
                    LocaleService.instance.isEnglish ? 'EN' : 'TR',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Yıldız Sandığı Butonu
          IconButton(
            tooltip: LocaleService.instance.tr('mysteryChest'),
            icon: const Text('🎁', style: TextStyle(fontSize: 19)),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: _showMysteryChestsDialog,
          ),
          const SizedBox(width: 4),

          // Menü Butonu (Gelişim Raporu, Çıkartma Albümü, Sandbox)
          IconButton(
            tooltip: 'Menü',
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 22),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: _showTopMenuBottomSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildAppLogoBanner() {
    final isEn = LocaleService.instance.isEnglish;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF4895EF), Color(0xFF4CC9F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4361EE).withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo Karakteri (Tıklanabilir Robi Seçici)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -4 * _animController.value),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AvatarSelectorDialog(
                        currentAvatarId: _currentAvatarId,
                        unlockedAvatarIds: _unlockedAvatarIds,
                        onSelectAvatar: (avatar) {
                          setState(() {
                            _currentAvatarId = avatar.id;
                          });
                          StorageService.instance.saveAvatar(avatar.id);
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(_currentAvatar.emoji, style: const TextStyle(fontSize: 34)),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4361EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Logo Başlığı ve İstatistikler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Text(
                      'ALGOKIDS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text('🚀', style: TextStyle(fontSize: 16)),
                  ],
                ),
                Text(
                  isEn ? 'Little Coders, Big Adventures! ✨' : 'Küçük Kodlayıcılar, Büyük Maceralar! ✨',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildMiniBadge('⭐ $_totalStars ${isEn ? "Stars" : "Yıldız"}', Colors.amber.shade400, Colors.black87),
                    _buildMiniBadge('🤖 ${_currentAvatar.name}', Colors.white24, Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildSimpleAgeCard({
    required String emoji,
    required String ageText,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: color.withAlpha(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withAlpha(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withAlpha(60), width: 1.5),
          ),
          child: Row(
            children: [
              // Emoji Rozeti
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(80), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),

              // Metin Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ageText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Ok İkonu
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
