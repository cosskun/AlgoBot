import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/avatar_model.dart';
import '../models/command_block.dart';
import '../models/level_data.dart';
import '../services/game_interpreter.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';
import '../widgets/command_drawer.dart';
import '../widgets/grid_painter.dart';
import '../widgets/workspace_view.dart';

enum BuildTool {
  robot,
  goal,
  obstacle,
  star,
  key,
  door,
  eraser,
}

class SandboxLevelBuilderScreen extends StatefulWidget {
  final AvatarModel avatar;

  const SandboxLevelBuilderScreen({
    super.key,
    required this.avatar,
  });

  @override
  State<SandboxLevelBuilderScreen> createState() => _SandboxLevelBuilderScreenState();
}

class _SandboxLevelBuilderScreenState extends State<SandboxLevelBuilderScreen> with TickerProviderStateMixin {
  late AnimationController _timeController;
  late AnimationController _stepController;

  final int _cols = 6;
  final int _rows = 6;
  GridPoint _robotStart = const GridPoint(0, 2);
  final int _robotStartDir = 1; // Sağa
  GridPoint _goal = const GridPoint(4, 2);

  final List<GridPoint> _obstacles = [];
  final List<GridPoint> _stars = [];
  final List<GridPoint> _keys = [];
  final List<GridPoint> _doors = [];

  BuildTool _selectedTool = BuildTool.obstacle;
  bool _isPlaying = false;

  // Oyun Durumu
  late GridPoint _robotPos;
  int _robotDir = 1;
  GridPoint? _targetPos;
  int? _targetDir;
  bool _isBumping = false;
  bool _hasKey = false;
  List<GridPoint> _remainingStars = [];
  List<GridPoint> _remainingKeys = [];
  List<GridPoint> _openedDoors = [];

  // Kod Blokları
  final List<CommandBlock> _mainBlocks = [];
  String? _highlightedBlockId;
  final GameInterpreter _interpreter = GameInterpreter();

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _stepController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _resetPlayState();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _stepController.dispose();
    _interpreter.stop();
    super.dispose();
  }

  void _resetPlayState({bool clearBlocks = false}) {
    _interpreter.stop();
    _robotPos = _robotStart;
    _robotDir = _robotStartDir;
    _targetPos = null;
    _targetDir = null;
    _isBumping = false;
    _hasKey = false;
    _remainingStars = List.from(_stars);
    _remainingKeys = List.from(_keys);
    _openedDoors = [];
    _highlightedBlockId = null;
    if (clearBlocks) {
      _mainBlocks.clear();
    }
  }

  LevelData _createCustomLevel() {
    final isEn = LocaleService.instance.isEnglish;
    return LevelData(
      id: 999,
      worldId: 1,
      title: isEn ? 'My Custom Sandbox Level' : 'Benim Özel Bölümüm',
      story: isEn ? 'Write code to solve the map you drew yourself!' : 'Kendi çizdiğin haritayı çözmek için kodlarını yaz!',
      hint: isEn ? 'Reach the flag in your maze.' : 'Kendi labirentinde hedefe ulaş.',
      cols: _cols,
      rows: _rows,
      robotStart: _robotStart,
      robotDir: _robotStartDir,
      goal: _goal,
      obstacles: _obstacles,
      stars: _stars,
      keys: _keys,
      doors: _doors,
      allowedBlocks: const [
        CommandType.forward,
        CommandType.turnRight,
        CommandType.turnLeft,
        CommandType.loopTimes,
      ],
      maxBlocksFor3Stars: 10,
    );
  }

  void _handleGridTap(int c, int r) {
    if (_isPlaying) return;
    SoundService.instance.playStep();

    final pt = GridPoint(c, r);
    setState(() {
      _obstacles.remove(pt);
      _stars.remove(pt);
      _keys.remove(pt);
      _doors.remove(pt);

      switch (_selectedTool) {
        case BuildTool.robot:
          _robotStart = pt;
          break;
        case BuildTool.goal:
          _goal = pt;
          break;
        case BuildTool.obstacle:
          if (pt != _robotStart && pt != _goal) _obstacles.add(pt);
          break;
        case BuildTool.star:
          if (pt != _robotStart && pt != _goal) _stars.add(pt);
          break;
        case BuildTool.key:
          if (pt != _robotStart && pt != _goal) _keys.add(pt);
          break;
        case BuildTool.door:
          if (pt != _robotStart && pt != _goal) _doors.add(pt);
          break;
        case BuildTool.eraser:
          break;
      }
    });
  }

  void _exportLevelCode() {
    SoundService.instance.playCelebration();
    final map = {
      'c': _cols,
      'r': _rows,
      'rs': [_robotStart.x, _robotStart.y],
      'g': [_goal.x, _goal.y],
      'o': _obstacles.map((p) => [p.x, p.y]).toList(),
      's': _stars.map((p) => [p.x, p.y]).toList(),
      'k': _keys.map((p) => [p.x, p.y]).toList(),
      'd': _doors.map((p) => [p.x, p.y]).toList(),
    };

    final jsonStr = jsonEncode(map);
    final code = 'ALGOKIDS_${base64Url.encode(utf8.encode(jsonStr))}';
    final isEn = LocaleService.instance.isEnglish;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(LocaleService.instance.tr('shareLevel'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEn ? 'Share this level code with your friends or scan with QR!' : 'Bu kodu arkadaşınla paylaşarak çizdiğin bölümü oynamasını sağla!',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              // Simüle QR Kodu Kutusu
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 72, color: Color(0xFF1E293B)),
                      const SizedBox(height: 4),
                      Text(
                        'AlgoKids QR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: SelectableText(
                  code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocaleService.instance.tr('codeCopied')),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(LocaleService.instance.tr('copyCode')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImportLevelDialog() {
    final textController = TextEditingController();
    final isEn = LocaleService.instance.isEnglish;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('📥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(LocaleService.instance.tr('importLevel'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEn ? 'Paste the code received from your friend:' : 'Arkadaşından aldığın bölüm kodunu buraya yapıştır:',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ALGOKIDS_ey...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEn ? 'Cancel' : 'İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = textController.text.trim();
                try {
                  String encoded = raw;
                  if (encoded.startsWith('ALGOKIDS_')) {
                    encoded = encoded.substring('ALGOKIDS_'.length);
                  }
                  final jsonStr = utf8.decode(base64Url.decode(encoded));
                  final map = jsonDecode(jsonStr) as Map<String, dynamic>;

                  setState(() {
                    _obstacles.clear();
                    _stars.clear();
                    _keys.clear();
                    _doors.clear();

                    if (map['rs'] is List) {
                      _robotStart = GridPoint(map['rs'][0] as int, map['rs'][1] as int);
                    }
                    if (map['g'] is List) {
                      _goal = GridPoint(map['g'][0] as int, map['g'][1] as int);
                    }
                    if (map['o'] is List) {
                      for (final pt in map['o']) {
                        _obstacles.add(GridPoint(pt[0] as int, pt[1] as int));
                      }
                    }
                    if (map['s'] is List) {
                      for (final pt in map['s']) {
                        _stars.add(GridPoint(pt[0] as int, pt[1] as int));
                      }
                    }
                    if (map['k'] is List) {
                      for (final pt in map['k']) {
                        _keys.add(GridPoint(pt[0] as int, pt[1] as int));
                      }
                    }
                    if (map['d'] is List) {
                      for (final pt in map['d']) {
                        _doors.add(GridPoint(pt[0] as int, pt[1] as int));
                      }
                    }

                    _resetPlayState();
                  });

                  Navigator.pop(context);
                  SoundService.instance.playCelebration();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'Level successfully loaded! 🚀' : 'Bölüm başarıyla yüklendi! 🚀'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'Invalid level code!' : 'Geçersiz bölüm kodu!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(LocaleService.instance.tr('loadLevel')),
            ),
          ],
        );
      },
    );
  }

  void _handleRun() {
    if (_interpreter.isRunning) return;

    setState(() {
      _resetPlayState();
    });

    final level = _createCustomLevel();

    _interpreter.run(
      mainBlocks: _mainBlocks,
      f1Blocks: const [],
      level: level,
      currentRobotPos: _robotPos,
      currentRobotDir: _robotDir,
      hasKey: _hasKey,
      remainingStars: _remainingStars,
      openedDoors: _openedDoors,
      onHighlightBlock: (id) => setState(() => _highlightedBlockId = id),
      onExecuteAction: (action) async {
        if (action == 'forward') {
          return await _stepForward();
        } else if (action == 'turn_right') {
          return await _stepTurn(1);
        } else if (action == 'turn_left') {
          return await _stepTurn(3);
        }
        return const StepResult(success: true);
      },
      onComplete: (success, stars, reason) {
        setState(() => _highlightedBlockId = null);
        if (success) {
          SoundService.instance.playCelebration();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Tebrikler! Kendi tasarladığın bölümü başarıyla çözdün!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          _showFailDialog(reason);
        }
      },
    );
  }

  void _showFailDialog(String? reason) {
    SoundService.instance.playBump();
    final isEn = LocaleService.instance.isEnglish;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(isEn ? 'Let\'s Adjust!' : 'Küçük Bir Düzeltme!'),
            ],
          ),
          content: Text(
            reason ?? (isEn ? 'Robi couldn\'t reach the goal. Adjust your code and retry!' : 'Robi hedefe ulaşamadı. Kodlarını kontrol edip tekrar dene!'),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _resetPlayState(clearBlocks: true);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEn ? 'Try Again 🔄' : 'Tekrar Dene 🔄'),
            ),
          ],
        );
      },
    );
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

    final isOutOfBounds = (nextX < 0 || nextX >= _cols || nextY < 0 || nextY >= _rows);
    final isObstacle = _obstacles.contains(next);
    final isLockedDoor = _doors.contains(next) && !_hasKey;

    if (isOutOfBounds || isObstacle || isLockedDoor) {
      SoundService.instance.playBump();
      setState(() => _isBumping = true);
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _isBumping = false);
      return const StepResult(success: false, reason: 'Engelle karşılaşıldı');
    }

    SoundService.instance.playStep();

    if (_doors.contains(next) && _hasKey) {
      SoundService.instance.playKeyOrDoor();
      setState(() => _openedDoors.add(next));
    }

    setState(() => _targetPos = next);
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

    return StepResult(success: true, reachedGoal: _robotPos == _goal);
  }

  Future<StepResult> _stepTurn(int delta) async {
    final next = (_robotDir + delta) % 4;
    SoundService.instance.playStep();
    setState(() => _targetDir = next);
    _stepController.reset();
    await _stepController.forward();
    setState(() {
      _robotDir = next;
      _targetDir = null;
    });
    return const StepResult(success: true);
  }

  @override
  Widget build(BuildContext context) {
    final customLevel = _createCustomLevel();
    final isEn = LocaleService.instance.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          isEn ? '🛠️ Sandbox Level Builder' : '🛠️ Kendi Bölümünü Çiz',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2B2D42)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2B2D42)),
        actions: [
          // Bölüm Paylaş Butonu
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF4361EE)),
            tooltip: LocaleService.instance.tr('shareLevel'),
            onPressed: _exportLevelCode,
          ),
          // Bölüm İçe Aktar Butonu
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981)),
            tooltip: LocaleService.instance.tr('importLevel'),
            onPressed: _showImportLevelDialog,
          ),
          IconButton(
            icon: Icon(_isPlaying ? Icons.edit : Icons.play_arrow, color: const Color(0xFF06D6A0)),
            tooltip: _isPlaying ? 'Çizim Modu' : 'Oyna & Test Et',
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                _resetPlayState();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bilgi ve Mod Seçimi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isPlaying
                          ? (isEn ? '🎮 PLAY & TEST MODE' : '🎮 OYUN & TEST MODU')
                          : (isEn ? '🎨 DRAW MODE: Tap grid cells' : '🎨 ÇİZİM MODU: Karelere dokun'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _isPlaying ? const Color(0xFF06D6A0) : const Color(0xFF4361EE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                            _resetPlayState();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPlaying ? const Color(0xFF4361EE) : const Color(0xFF06D6A0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _isPlaying ? (isEn ? '✏️ Edit' : '✏️ Düzenle') : (isEn ? '▶ Test' : '▶ Test Et'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Çizim Araç Paleti (Sadece Çizim Modunda)
            if (!_isPlaying)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: const Color(0xFFF8FAFC),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildToolButton(BuildTool.obstacle, isEn ? '🪨 Rock' : '🪨 Taş', const Color(0xFF78909C)),
                      _buildToolButton(BuildTool.star, isEn ? '⭐ Star' : '⭐ Yıldız', const Color(0xFFFFC107)),
                      _buildToolButton(BuildTool.key, isEn ? '🔑 Key' : '🔑 Anahtar', const Color(0xFFFFB300)),
                      _buildToolButton(BuildTool.door, isEn ? '🚪 Door' : '🚪 Kapı', const Color(0xFFD32F2F)),
                      _buildToolButton(BuildTool.robot, '🤖 Robi', const Color(0xFF4361EE)),
                      _buildToolButton(BuildTool.goal, isEn ? '🚩 Goal' : '🚩 Hedef', const Color(0xFFFF5252)),
                      _buildToolButton(BuildTool.eraser, isEn ? '🧹 Eraser' : '🧹 Silgi', Colors.grey),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          SoundService.instance.playBlockSnap();
                          setState(() {
                            _obstacles.clear();
                            _stars.clear();
                            _keys.clear();
                            _doors.clear();
                            _resetPlayState();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEn ? '🧹 Map cleared.' : '🧹 Çizilen tüm harita temizlendi.'),
                              duration: const Duration(milliseconds: 1200),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isEn ? 'Clear Grid' : 'Haritayı Temizle',
                                style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Canvas Çizim & Oyun Alanı
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapUp: (details) {
                          if (_isPlaying) return;
                          const pad = 16.0;
                          final availW = constraints.maxWidth - pad * 2;
                          final availH = constraints.maxHeight - pad * 2;
                          final cellSize = (availW / _cols < availH / _rows ? availW / _cols : availH / _rows).clamp(35.0, 75.0);
                          final offsetX = (constraints.maxWidth - _cols * cellSize) / 2;
                          final offsetY = (constraints.maxHeight - _rows * cellSize) / 2;

                          final localPos = details.localPosition;
                          final col = ((localPos.dx - offsetX) / cellSize).floor();
                          final row = ((localPos.dy - offsetY) / cellSize).floor();

                          if (col >= 0 && col < _cols && row >= 0 && row < _rows) {
                            _handleGridTap(col, row);
                          }
                        },
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_timeController, _stepController]),
                          builder: (context, child) {
                            return CustomPaint(
                              painter: GridPainter(
                                level: customLevel,
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
                                avatar: widget.avatar,
                                time: _timeController.value * 10,
                              ),
                              child: Container(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Çizim Modu / Oyun Modu Alt Paneli
            if (_isPlaying) ...[
              // Çalıştır & Sıfırla Butonları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _interpreter.isRunning ? null : _handleRun,
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: Text(LocaleService.instance.tr('run'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06D6A0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        SoundService.instance.playBlockSnap();
                        _interpreter.stop();
                        setState(() {
                          _resetPlayState();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD166),
                        foregroundColor: const Color(0xFF78350F),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(LocaleService.instance.tr('reset'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),

              // Komut Çekmecesi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CommandDrawer(
                  allowedBlocks: customLevel.allowedBlocks,
                  onAddBlock: (type) {
                    setState(() {
                      _mainBlocks.add(CommandBlock(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        type: type,
                      ));
                    });
                  },
                ),
              ),

              // Kod Blokları Workspace
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
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
                            Text(
                              LocaleService.instance.tr('codeOrder'),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF475569)),
                            ),
                            TextButton(
                              onPressed: () {
                                SoundService.instance.playBlockSnap();
                                setState(() {
                                  _mainBlocks.clear();
                                });
                              },
                              child: Text('${LocaleService.instance.tr('clear')} 🗑️', style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: WorkspaceView(
                          blocks: _mainBlocks,
                          highlightedBlockId: _highlightedBlockId,
                          level: customLevel,
                          onReorderBlocks: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = _mainBlocks.removeAt(oldIndex);
                              _mainBlocks.insert(newIndex, item);
                            });
                          },
                          onInsertBlockAt: (insertIndex, type) {
                            setState(() {
                              final newBlock = CommandBlock(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                type: type,
                              );
                              if (insertIndex >= _mainBlocks.length) {
                                _mainBlocks.add(newBlock);
                              } else {
                                _mainBlocks.insert(insertIndex, newBlock);
                              }
                            });
                          },
                          onDeleteBlock: (block) {
                            setState(() {
                              _mainBlocks.remove(block);
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
            ] else ...[
              // Çizim Modu İpuçları
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF4361EE), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEn
                            ? 'Select a tool from above, tap on grid cells to place obstacles, stars, keys, and doors!'
                            : 'Yukarıdan bir araç seç, haritaya dokunarak taş, yıldız, anahtar ve kapı yerleştir!',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(BuildTool tool, String label, Color color) {
    final isSelected = (_selectedTool == tool);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            SoundService.instance.playStep();
            setState(() {
              _selectedTool = tool;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFCBD5E1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
