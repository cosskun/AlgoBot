import 'package:flutter/material.dart';
import '../models/level_data.dart';

class WorldMapScreen extends StatefulWidget {
  final int unlockedLevelId;
  final Map<int, int> levelStars;
  final Function(int levelIndex) onSelectLevel;

  const WorldMapScreen({
    super.key,
    required this.unlockedLevelId,
    required this.levelStars,
    required this.onSelectLevel,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialWorldIdx = ((widget.unlockedLevelId - 1) ~/ 10).clamp(0, LevelData.worlds.length - 1);
    _tabController = TabController(
      length: LevelData.worlds.length,
      vsync: this,
      initialIndex: initialWorldIdx,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          '🗺️ 100 Bölüm Haritası',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2B2D42)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2B2D42)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF4361EE),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4361EE),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: LevelData.worlds.map((w) {
            return Tab(text: '${w.badge} ${w.id}. Dünya');
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: LevelData.worlds.map((world) {
          final worldLevels = LevelData.allLevels.where((l) => l.worldId == world.id).toList();
          final int worldStartLvl = (world.id - 1) * 10 + 1;
          final int worldEndLvl = world.id * 10;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: world.color.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: Text(world.badge, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              world.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bölüm $worldStartLvl - $worldEndLvl',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: world.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              world.description,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: worldLevels.length,
                itemBuilder: (context, idx) {
                  final lvl = worldLevels[idx];
                  final isUnlocked = lvl.id <= widget.unlockedLevelId;
                  final stars = widget.levelStars[lvl.id] ?? 0;
                  final allIdx = LevelData.allLevels.indexOf(lvl);

                  return InkWell(
                    onTap: isUnlocked
                        ? () {
                            Navigator.pop(context);
                            widget.onSelectLevel(allIdx);
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🔒 ${lvl.id}. Bölüm kilitli! Açmak için önce ${lvl.id - 1}. bölümü tamamlamalısın.'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isUnlocked ? Colors.white : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUnlocked ? world.color : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: world.color.withAlpha(45),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${lvl.id}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isUnlocked ? const Color(0xFF1E293B) : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUnlocked
                                ? (stars > 0 ? ('⭐' * stars) : '⚪')
                                : '🔒',
                            style: const TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
