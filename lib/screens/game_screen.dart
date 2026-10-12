import 'package:flutter/material.dart';
import '../models/age_mode.dart';
import '../models/avatar_model.dart';
import '../models/command_block.dart';
import '../models/level_data.dart';
import '../services/daily_challenge_service.dart';
import '../services/game_interpreter.dart';
import '../services/locale_service.dart';
import '../services/solution_solver.dart';
import '../services/sound_service.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../widgets/age_selector_dialog.dart';
import '../widgets/avatar_selector_dialog.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/command_drawer.dart';
import '../widgets/grid_painter.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/sticker_album_dialog.dart';
import '../widgets/workspace_view.dart';
import 'age_selection_screen.dart';
import 'sandbox_level_builder_screen.dart';
import 'world_map_screen.dart';

class GameScreen extends StatefulWidget {
  final AgeMode initialAgeMode;
  final int initialLevelIndex;
  final LevelData? customLevel;

  const GameScreen({
    super.key,
    this.initialAgeMode = AgeMode.explorer,
    this.initialLevelIndex = 0,
    this.customLevel,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _timeController;
  late AnimationController _stepController;

  late AgeMode _currentAgeMode;

  int _currentLevelIndex = 0;
  int _unlockedLevelId = 1;
  final Map<int, int> _levelStars = {};

  String _currentAvatarId = 'classic_robi';
  final Set<String> _unlockedAvatarIds = {'classic_robi'};

  late GridPoint _robotPos;
  late int _robotDir;
  GridPoint? _targetPos;
  int? _targetDir;
  bool _isBumping = false;
  bool _hasKey = false;
  List<GridPoint> _remainingStars = [];
  List<GridPoint> _remainingKeys = [];
  List<GridPoint> _openedDoors = [];

  final List<CommandBlock> _mainBlocks = [];
  final List<CommandBlock> _f1Blocks = [];
  String _activeTab = 'main';
  String? _highlightedBlockId;

  final GameInterpreter _interpreter = GameInterpreter();

  LevelData get _currentLevel => widget.customLevel ?? LevelData.allLevels[_currentLevelIndex];
  AvatarModel get _currentAvatar =>
      AvatarModel.allAvatars.firstWhere((a) => a.id == _currentAvatarId, orElse: () => AvatarModel.allAvatars.first);

  @override
  void initState() {
    super.initState();
    final storage = StorageService.instance;
    _currentAgeMode = widget.initialAgeMode;
    _currentAvatarId = storage.avatarId;
    _unlockedAvatarIds.addAll(storage.unlockedAvatars);
    _unlockedLevelId = storage.unlockedLevelId;
    _levelStars.addAll(storage.levelStars);

    _currentLevelIndex = widget.initialLevelIndex;
    _timeController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _stepController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _loadLevel(_currentLevelIndex);
  }

  @override
  void dispose() {
    _timeController.dispose();
    _stepController.dispose();
    _interpreter.stop();
    super.dispose();
  }

  void _loadLevel(int index) {
    if (widget.customLevel == null && (index < 0 || index >= LevelData.allLevels.length)) return;
    setState(() {
      _currentLevelIndex = index;
      _resetGameState();
      _mainBlocks.clear();
      _f1Blocks.clear();
      _activeTab = 'main';
      _highlightedBlockId = null;

      if (_currentLevel.initialCode != null && _currentAgeMode == AgeMode.master) {
        for (final b in _currentLevel.initialCode!) {
          _mainBlocks.add(b.clone());
        }
      }
    });
  }

  void _resetGameState() {
    _robotPos = _currentLevel.robotStart;
    _robotDir = _currentLevel.robotDir;
    _targetPos = null;
    _targetDir = null;
    _isBumping = false;
    _hasKey = false;
    _remainingStars = List.from(_currentLevel.stars);
    _remainingKeys = List.from(_currentLevel.keys);
    _openedDoors = [];
  }

  void _showAgeSelectorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AgeSelectorDialog(
          currentMode: _currentAgeMode,
          onSelectMode: (newMode) {
            setState(() {
              _currentAgeMode = newMode;
            });
            StorageService.instance.saveAgeMode(newMode);
            _loadLevel(0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('👶 ${newMode.title} seçildi! 1. Bölümden başlandı.'),
                backgroundColor: newMode.color,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ProfileDialog(
          unlockedLevelId: _unlockedLevelId,
          totalStars: _totalStarsCount,
          currentAvatar: _currentAvatar,
          currentAgeMode: _currentAgeMode,
          onChangeAgeMode: _showAgeSelectorDialog,
        );
      },
    );
  }

  void _showStickerAlbumDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StickerAlbumDialog(
          unlockedLevelId: _unlockedLevelId,
        );
      },
    );
  }

  void _playVoiceNarration() {
    final isEn = LocaleService.instance.isEnglish;
    final textToSpeak = (_currentAgeMode == AgeMode.mini)
        ? (isEn ? 'Tap the arrow buttons to guide Robi to the flag! Don\'t forget to collect stars!' : 'Robi\'yi bayrağa ulaştırmak için ok butonlarına bas! Yıldızları toplamayı unutma!')
        : '${_currentLevel.story} ${_currentLevel.hint}';

    SpeechService.speakTurkish(
      context: context,
      text: textToSpeak,
      avatarEmoji: _currentAvatar.emoji,
    );
  }

  // --- MİNİ MOD DOKUN-İLERLE METODLARI ---
  void _onMiniInstantMove() async {
    if (_stepController.isAnimating) return;
    final res = await _stepForward();
    if (res.reachedGoal) {
      _handleLevelSuccess(_currentLevel.stars.length - _remainingStars.length);
    }
  }

  void _onMiniInstantTurnLeft() async {
    if (_stepController.isAnimating) return;
    await _stepTurn(3);
  }

  void _onMiniInstantTurnRight() async {
    if (_stepController.isAnimating) return;
    await _stepTurn(1);
  }

  // --- KAŞİF & USTA MODU KOD ÇALIŞTIRMA ---
  void _handleRun({bool isDemo = false}) {
    if (_interpreter.isRunning) return;

    setState(() {
      _resetGameState();
    });

    _interpreter.run(
      mainBlocks: _mainBlocks,
      f1Blocks: _f1Blocks,
      level: _currentLevel,
      currentRobotPos: _robotPos,
      currentRobotDir: _robotDir,
      hasKey: _hasKey,
      remainingStars: _remainingStars,
      openedDoors: _openedDoors,
      onHighlightBlock: (blockId) {
        setState(() {
          _highlightedBlockId = blockId;
        });
      },
      onExecuteAction: (action) async {
        if (action == 'forward') {
          return await _stepForward();
        } else if (action == 'turn_right') {
          return await _stepTurn(1);
        } else if (action == 'turn_left') {
          return await _stepTurn(3);
        } else if (action == 'check_obstacle') {
          return StepResult(success: _isObstacleAhead());
        }
        return const StepResult(success: true);
      },
      onComplete: (success, starsCollected, reason) {
        setState(() {
          _highlightedBlockId = null;
        });

        if (success) {
          if (isDemo) {
            _showDemoCompletedDialog();
          } else {
            _handleLevelSuccess(starsCollected);
          }
        } else {
          _showFailDialog(reason);
        }
      },
    );
  }

  // --- ADIM ADIM (DEBUGGER) ÇALIŞTIRMA ---
  void _handleStep() async {
    if (_interpreter.isRunning) return;

    if (!_interpreter.isStepMode || !_interpreter.hasNextStep) {
      _resetGameState();
      _interpreter.prepareStepMode(
        mainBlocks: _mainBlocks,
        f1Blocks: _f1Blocks,
      );
      setState(() {});
    }

    final res = await _interpreter.executeSingleStep(
      onHighlightBlock: (blockId) {
        setState(() {
          _highlightedBlockId = blockId;
        });
      },
      onExecuteAction: (action) async {
        if (action == 'forward') {
          return await _stepForward();
        } else if (action == 'turn_right') {
          return await _stepTurn(1);
        } else if (action == 'turn_left') {
          return await _stepTurn(3);
        } else if (action == 'check_obstacle') {
          return StepResult(success: _isObstacleAhead());
        }
        return const StepResult(success: true);
      },
    );

    if (res != null) {
      if (res.reachedGoal) {
        final starsCollected = _currentLevel.stars.length - _remainingStars.length;
        _handleLevelSuccess(starsCollected);
      } else if (!res.success) {
        _showFailDialog(res.reason);
      } else if (!_interpreter.hasNextStep && _robotPos != _currentLevel.goal) {
        final isEn = LocaleService.instance.isEnglish;
        _showFailDialog(isEn ? 'Commands ended but Robi hasn\'t reached the goal yet.' : 'Komutlar bitti ama Robi henüz hedefe ulaşamadı.');
      }
    }
  }

  void _showDemoCompletedDialog() {
    final isEn = LocaleService.instance.isEnglish;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(isEn ? 'Ideal Solution Demonstrated!' : 'İdeal Çözüm Gösterildi!'),
            ],
          ),
          content: Text(
            isEn
                ? 'Here is how the most optimal 3-star algorithm solves this puzzle!\n\nNow try it yourself or jump to the next level.'
                : 'İşte 3 yıldız kazandıran en verimli algoritma böyle çalışıyor!\n\nŞimdi ister bu mantıkla tekrar oyna, ister sonraki bölüme geç.',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _resetGameState();
                });
              },
              child: Text(isEn ? 'Try Myself ↺' : 'Kendim Dene ↺'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (widget.customLevel == null && _currentLevelIndex + 1 < LevelData.allLevels.length) {
                  _loadLevel(_currentLevelIndex + 1);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0),
                foregroundColor: Colors.white,
              ),
              child: Text(isEn ? 'Next Level ➔' : 'Sonraki Bölüm ➔'),
            ),
          ],
        );
      },
    );
  }

  void _watchOptimalSolution() async {
    final solution = SolutionSolver.solve(_currentLevel);
    setState(() {
      _resetGameState();
      _mainBlocks.clear();
      _f1Blocks.clear();
      for (final b in solution.mainBlocks) {
        _mainBlocks.add(b.clone());
      }
      for (final b in solution.f1Blocks) {
        _f1Blocks.add(b.clone());
      }
    });

    final isEn = LocaleService.instance.isEnglish;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEn ? '💡 Demonstrating optimal 3-star solution...' : '💡 3 Yıldızlı en verimli çözüm çalıştırılıyor...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        duration: const Duration(milliseconds: 1500),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 400));
    _handleRun(isDemo: true);
  }

  bool _isObstacleAhead() {
    final deltas = [
      const GridPoint(0, -1),
      const GridPoint(1, 0),
      const GridPoint(0, 1),
      const GridPoint(-1, 0),
    ];
    final nextX = _robotPos.x + deltas[_robotDir].x;
    final nextY = _robotPos.y + deltas[_robotDir].y;
    final next = GridPoint(nextX, nextY);

    final isOutOfBounds = (nextX < 0 || nextX >= _currentLevel.cols || nextY < 0 || nextY >= _currentLevel.rows);
    final isObstacle = _currentLevel.obstacles.contains(next);
    final isLockedDoor = _currentLevel.doors.contains(next) && !_hasKey;

    return isOutOfBounds || isObstacle || isLockedDoor;
  }

  Future<StepResult> _stepForward() async {
    final deltas = [
      const GridPoint(0, -1),
      const GridPoint(1, 0),
      const GridPoint(0, 1),
      const GridPoint(-1, 0),
    ];
    final nextX = _robotPos.x + deltas[_robotDir].x;
    final nextY = _robotPos.y + deltas[_robotDir].y;
    final next = GridPoint(nextX, nextY);

    if (_isObstacleAhead()) {
      SoundService.instance.playBump();
      setState(() {
        _isBumping = true;
      });
      await Future.delayed(const Duration(milliseconds: 250));
      setState(() {
        _isBumping = false;
      });
      final isEn = LocaleService.instance.isEnglish;
      return StepResult(success: false, reason: isEn ? 'Obstacle or locked door ahead!' : 'Önünde engel veya kilitli kapı var!');
    }

    SoundService.instance.playStep();

    if (_currentLevel.doors.contains(next) && _hasKey) {
      SoundService.instance.playKeyOrDoor();
      setState(() {
        _openedDoors.add(next);
      });
    }

    setState(() {
      _targetPos = next;
    });

    _stepController.reset();
    await _stepController.forward();

    setState(() {
      _robotPos = next;
      _targetPos = null;

      if (_remainingStars.contains(next)) {
        _remainingStars.remove(next);
        SoundService.instance.playStarCollect();
      }
      if (_remainingKeys.contains(next)) {
        _remainingKeys.remove(next);
        _hasKey = true;
        SoundService.instance.playKeyOrDoor();
      }
    });

    final reachedGoal = (_robotPos == _currentLevel.goal);
    return StepResult(success: true, reachedGoal: reachedGoal);
  }

  Future<StepResult> _stepTurn(int dirDelta) async {
    final nextDir = (_robotDir + dirDelta) % 4;
    SoundService.instance.playStep();
    setState(() {
      _targetDir = nextDir;
    });

    _stepController.reset();
    await _stepController.forward();

    setState(() {
      _robotDir = nextDir;
      _targetDir = null;
    });

    return const StepResult(success: true);
  }

  void _handleLevelSuccess(int starsCollected) {
    SoundService.instance.playCelebration();

    if (_currentLevel.id == 9990) {
      DailyChallengeService.instance.markTodayCompleted();
    }

    int totalBlocksUsed = _mainBlocks.length + _f1Blocks.length;
    int starsEarned = 1;
    if (_remainingStars.isEmpty) starsEarned++;
    if (_currentAgeMode == AgeMode.mini ||
        (totalBlocksUsed <= _currentLevel.maxBlocksFor3Stars && _remainingStars.isEmpty)) {
      starsEarned = 3;
    }

    if (widget.customLevel == null) {
      final prevStars = _levelStars[_currentLevel.id] ?? 0;
      if (starsEarned > prevStars) {
        _levelStars[_currentLevel.id] = starsEarned;
      }

      if (_currentLevel.id + 1 > _unlockedLevelId) {
        _unlockedLevelId = _currentLevel.id + 1;
      }
      StorageService.instance.saveLevelProgress(_currentLevel.id, starsEarned);
    }

    AvatarModel? newAvatar;
    if (_currentLevel.rewardAvatarId != null && !_unlockedAvatarIds.contains(_currentLevel.rewardAvatarId)) {
      _unlockedAvatarIds.add(_currentLevel.rewardAvatarId!);
      StorageService.instance.unlockAvatar(_currentLevel.rewardAvatarId!);
      newAvatar = AvatarModel.allAvatars.firstWhere((a) => a.id == _currentLevel.rewardAvatarId);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CelebrationDialog(
          starsEarned: starsEarned,
          blocksUsed: totalBlocksUsed,
          maxBlocksFor3Stars: _currentLevel.maxBlocksFor3Stars,
          newlyUnlockedAvatar: newAvatar,
          onWatchSolution: () => _watchOptimalSolution(),
          onReplay: () {
            _resetGameState();
            setState(() {});
          },
          onNextLevel: () {
            if (widget.customLevel != null) {
              Navigator.pop(context);
            } else if (_currentLevelIndex + 1 < LevelData.allLevels.length) {
              _loadLevel(_currentLevelIndex + 1);
            }
          },
        );
      },
    );
  }

  void _showFailDialog(String? reason) {
    SoundService.instance.playBump();
    final isEn = LocaleService.instance.isEnglish;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('💥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(isEn ? 'Oops, Robot Stopped!' : 'Eyvah, Robot Durdu!'),
            ],
          ),
          content: Text(
            reason ?? (isEn ? 'Robi hit an obstacle or went off bounds. Let\'s fix the code and retry!' : 'Robi bir engelle karşılaştı ya da yolunu bulamadı. Hadi kodları düzeltip tekrar deneyelim! 💪'),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _watchOptimalSolution();
              },
              icon: const Icon(Icons.lightbulb, color: Color(0xFF6366F1), size: 18),
              label: Text(LocaleService.instance.tr('watchSolution'), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _resetGameState();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
              ),
              child: Text(LocaleService.instance.tr('replay')),
            ),
          ],
        );
      },
    );
  }

  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AvatarSelectorDialog(
          currentAvatarId: _currentAvatarId,
          unlockedAvatarIds: _unlockedAvatarIds,
          onSelectAvatar: (avatar) {
            setState(() {
              _currentAvatarId = avatar.id;
            });
            StorageService.instance.saveAvatar(avatar.id);
          },
        );
      },
    );
  }

  void _showHintDialog() {
    final isEn = LocaleService.instance.isEnglish;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(LocaleService.instance.tr('hint')),
            ],
          ),
          content: Text(
            _currentLevel.hint,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEn ? 'Got it, Thanks!' : 'Anladım, Teşekkürler!'),
            ),
          ],
        );
      },
    );
  }

  void _showMoreGameOptionsSheet() {
    final isEn = LocaleService.instance.isEnglish;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
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
                  isEn ? 'Game Menu & Options' : 'Oyun Menüsü & Seçenekler',
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
                    child: Text(LocaleService.instance.languageEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    isEn ? 'Language: English 🇬🇧' : 'Dil: Türkçe 🇹🇷',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  subtitle: Text(
                    isEn ? 'Tap to switch to Turkish' : 'İngilizceye geçmek için dokun',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF4361EE)),
                  onTap: () {
                    Navigator.pop(context);
                    LocaleService.instance.toggleLanguage();
                    setState(() {});
                  },
                ),
                const Divider(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_rounded, color: Color(0xFFEF4444)),
                  ),
                  title: Text(
                    isEn ? 'Return to Home Page / Main Menu' : 'Ana Sayfaya Dön',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFEF4444)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFEF4444)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateBackToMenu();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF4361EE)),
                  ),
                  title: Text(
                    LocaleService.instance.tr('profile'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _showProfileDialog();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: Color(0xFFFFB300)),
                  ),
                  title: Text(
                    LocaleService.instance.tr('stickers'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _showStickerAlbumDialog();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette, color: Color(0xFF06D6A0)),
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
                        builder: (context) => SandboxLevelBuilderScreen(avatar: _currentAvatar),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _totalStarsCount => _levelStars.values.fold(0, (sum, stars) => sum + stars);

  void _navigateBackToMenu() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AgeSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBackToMenu();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2B2D42), size: 20),
            tooltip: 'Ana Menüye Dön',
            onPressed: _navigateBackToMenu,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            InkWell(
              onTap: _showAvatarDialog,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _currentAvatar.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _currentAvatar.primaryColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_currentAvatar.emoji, style: const TextStyle(fontSize: 18)),
                    const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF4361EE)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_currentLevel.id}. ${LocaleService.instance.tr('level')}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B2D42),
              ),
            ),
          ],
        ),
        actions: [
          // İpucu Butonu
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B), size: 22),
            tooltip: LocaleService.instance.tr('hint'),
            visualDensity: VisualDensity.compact,
            onPressed: _showHintDialog,
          ),

          // Harita Butonu
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Color(0xFF4361EE), size: 22),
            tooltip: 'Harita',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorldMapScreen(
                    unlockedLevelId: _unlockedLevelId,
                    levelStars: _levelStars,
                    onSelectLevel: _loadLevel,
                  ),
                ),
              );
            },
          ),

          // Menü Butonu (Profil, Çıkartmalar, Sandbox, Dil)
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 22),
            tooltip: 'Menü',
            visualDensity: VisualDensity.compact,
            onPressed: _showMoreGameOptionsSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Robi Konuşma Kutusu & Sesli Anlatıcı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: const Border(left: BorderSide(color: Color(0xFF4CC9F0), width: 5)),
                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Text(_currentAvatar.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _currentAgeMode == AgeMode.mini
                          ? (LocaleService.instance.isEnglish ? 'Tap the arrow buttons to guide Robi! 🚩' : 'Ok tuşlarına basarak Robi\'yi bayrağa götür! 🚩')
                          : _currentLevel.story,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                  InkWell(
                    onTap: _playVoiceNarration,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7DD3FC)),
                      ),
                      child: const Icon(Icons.volume_up, color: Color(0xFF0284C7), size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Oyun Canvas Izgarası
            Expanded(
              flex: (_currentAgeMode == AgeMode.mini) ? 5 : 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_timeController, _stepController]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: GridPainter(
                          level: _currentLevel,
                          robotPos: _robotPos,
                          robotDir: _robotDir,
                          animProgress: _stepController.value,
                          targetPos: _targetPos,
                          targetDir: _targetDir,
                          isBumping: _isBumping,
                          hasKey: _hasKey,
                          remainingStars: _remainingStars,
                          remainingKeys: _remainingKeys,
                          openedDoors: _openedDoors,
                          avatar: _currentAvatar,
                          time: _timeController.value * 10,
                        ),
                        child: Container(),
                      );
                    },
                  ),
                ),
              ),
            ),

            // --- YAŞ GRUBUNA GÖRE KONTROL PANELİ ---
            if (_currentAgeMode == AgeMode.mini)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniButton(
                      emoji: '↶',
                      label: LocaleService.instance.isEnglish ? 'Left' : 'Sola',
                      color: const Color(0xFFF97316),
                      onTap: _onMiniInstantTurnLeft,
                    ),
                    _buildMiniButton(
                      iconWidget: AnimatedRotation(
                        turns: _robotDir / 4.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutBack,
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      label: LocaleService.instance.isEnglish ? 'FORWARD' : 'İLERİ',
                      color: const Color(0xFF06D6A0),
                      isBig: true,
                      onTap: _onMiniInstantMove,
                    ),
                    _buildMiniButton(
                      emoji: '↷',
                      label: LocaleService.instance.isEnglish ? 'Right' : 'Sağa',
                      color: const Color(0xFF8B5CF6),
                      onTap: _onMiniInstantTurnRight,
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    // ÇALIŞTIR (RUN) BUTONU
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: _interpreter.isRunning ? null : _handleRun,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: Text(
                          LocaleService.instance.tr('run'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06D6A0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // ADIM ADIM (STEP) BUTONU
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: _interpreter.isRunning ? null : _handleStep,
                        icon: const Icon(Icons.skip_next, size: 20),
                        label: Text(
                          LocaleService.instance.tr('step'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // SIFIRLA (RESET) BUTONU
                    ElevatedButton(
                      onPressed: () {
                        SoundService.instance.playBlockSnap();
                        _interpreter.stop();
                        setState(() {
                          _resetGameState();
                          _highlightedBlockId = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD166),
                        foregroundColor: const Color(0xFF78350F),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(LocaleService.instance.tr('reset'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),

              // Komut Çekmecesi (Ekrana Tam Sığan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CommandDrawer(
                  allowedBlocks: _currentLevel.allowedBlocks,
                  onAddBlock: (type) {
                    setState(() {
                      final newBlock = CommandBlock(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        type: type,
                      );
                      if (_activeTab == 'f1') {
                        _f1Blocks.add(newBlock);
                      } else {
                        _mainBlocks.add(newBlock);
                      }
                    });
                  },
                ),
              ),

              // Çalışma Alanı (Workspace)
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentLevel.enableFunctionF1 && _currentAgeMode == AgeMode.master)
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        visualDensity: VisualDensity.compact,
                                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                        label: Text(
                                          LocaleService.instance.isEnglish ? '🚀 Main' : '🚀 Ana Kod',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        selected: _activeTab == 'main',
                                        onSelected: (val) => setState(() => _activeTab = 'main'),
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        visualDensity: VisualDensity.compact,
                                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                        label: const Text('✨ F1', style: TextStyle(fontSize: 12)),
                                        selected: _activeTab == 'f1',
                                        onSelected: (val) => setState(() => _activeTab = 'f1'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Text(
                                LocaleService.instance.tr('codeOrder'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF475569)),
                              ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                SoundService.instance.playBlockSnap();
                                setState(() {
                                  if (_activeTab == 'f1') {
                                    _f1Blocks.clear();
                                  } else {
                                    _mainBlocks.clear();
                                  }
                                });
                              },
                              child: Text('${LocaleService.instance.tr('clear')} 🗑️', style: const TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: WorkspaceView(
                          blocks: (_activeTab == 'f1') ? _f1Blocks : _mainBlocks,
                          highlightedBlockId: _highlightedBlockId,
                          level: _currentLevel,
                          onReorderBlocks: (oldIndex, newIndex) {
                            setState(() {
                              final list = (_activeTab == 'f1') ? _f1Blocks : _mainBlocks;
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = list.removeAt(oldIndex);
                              list.insert(newIndex, item);
                            });
                          },
                          onInsertBlockAt: (insertIndex, type) {
                            setState(() {
                              final list = (_activeTab == 'f1') ? _f1Blocks : _mainBlocks;
                              final newBlock = CommandBlock(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                type: type,
                              );
                              if (insertIndex >= list.length) {
                                list.add(newBlock);
                              } else {
                                list.insert(insertIndex, newBlock);
                              }
                            });
                          },
                          onDeleteBlock: (block) {
                            setState(() {
                              _mainBlocks.remove(block);
                              _f1Blocks.remove(block);
                            });
                          },
                          onAddChildBlock: (parent, childType) {
                            setState(() {
                              parent.children.add(CommandBlock(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                type: childType,
                              ));
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMiniButton({
    String? emoji,
    Widget? iconWidget,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isBig = false,
  }) {
    final size = isBig ? 84.0 : 68.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget
            else
              Text(emoji ?? '', style: TextStyle(fontSize: isBig ? 32 : 24)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isBig ? 13 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
