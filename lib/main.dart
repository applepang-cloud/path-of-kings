import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'game_state.dart';
import 'scene.dart';
import 'loot_overlay.dart';

void main() => runApp(const PathOfKingsApp());

class PathOfKingsApp extends StatelessWidget {
  const PathOfKingsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Path of Kings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFF1c1410),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final game = GameState();
  Timer? _timer;
  Duration _last = Duration.zero;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final now = _stopwatch.elapsed;
      double dt = (now - _last).inMicroseconds / 1e6;
      _last = now;
      if (dt > 0.1) dt = 0.1; // 프레임 튐 방지
      game.tick(dt);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: game,
          builder: (context, _) {
            return Column(
              children: [
                _TopBar(game: game),
                // 1인칭 전투 화면
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: SceneView(game: game)),
                      // 전리품 선택 오버레이
                      if (game.phase == Phase.loot && game.lootChoices.length == 2)
                        Positioned.fill(
                          child: LootOverlay(
                            game: game,
                            choices: game.lootChoices,
                          ),
                        ),
                    ],
                  ),
                ),
                _PlayerBar(game: game),
                _EquipmentGrid(game: game),
                const _NavBar(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── 상단 바 ─────────────────────────
class _TopBar extends StatelessWidget {
  final GameState game;
  const _TopBar({required this.game});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF2a1d12),
      child: Row(
        children: [
          const _RoundIcon(emoji: '⚙️'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3a2a1a),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF7a5a3a), width: 2),
            ),
            child: Text(game.zoneLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          const Spacer(),
          _Currency(emoji: '🪙', value: game.gold, color: const Color(0xFFFFD54F)),
          const SizedBox(width: 6),
          _Currency(emoji: '💎', value: game.gems, color: const Color(0xFF4FC3F7)),
        ],
      ),
    );
  }
}

class _Currency extends StatelessWidget {
  final String emoji;
  final int value;
  final Color color;
  const _Currency(
      {required this.emoji, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3a2a1a),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7a5a3a), width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(_fmt(value),
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }
}

class _RoundIcon extends StatelessWidget {
  final String emoji;
  const _RoundIcon({required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF3a2a1a),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF7a5a3a), width: 2),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}

// ───────────────────────── 플레이어 바 (레벨/HP/EXP) ─────────────────────────
class _PlayerBar extends StatelessWidget {
  final GameState game;
  const _PlayerBar({required this.game});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2a1d12),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          // 캐릭터 초상
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF4a3826),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8a6a4a), width: 2),
            ),
            child: const Text('🧑‍🌾', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text('Lv.${game.level}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                  Text('⚔️ 전투력 ${game.power}',
                      style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 3),
                _Bar(
                  value: game.playerHp / game.maxHp,
                  color: const Color(0xFFE53935),
                  bg: const Color(0xFF5a1a1a),
                  label: 'HP ${game.playerHp.round()}/${game.maxHp}',
                  height: 14,
                ),
                const SizedBox(height: 3),
                _Bar(
                  value: game.xp / game.xpNeeded,
                  color: const Color(0xFF43A047),
                  bg: const Color(0xFF1a3a1a),
                  label: 'EXP ${game.xp}/${game.xpNeeded}',
                  height: 11,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  final Color bg;
  final String label;
  final double height;
  const _Bar(
      {required this.value,
      required this.color,
      required this.bg,
      required this.label,
      required this.height});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        children: [
          Container(height: height, color: bg),
          FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SizedBox(
            height: height,
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: height - 4,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 2)
                      ])),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 장비 슬롯 그리드 ─────────────────────────
class _EquipmentGrid extends StatelessWidget {
  final GameState game;
  const _EquipmentGrid({required this.game});
  @override
  Widget build(BuildContext context) {
    final slots = Slot.values;
    return Container(
      color: const Color(0xFF3a2a1a),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (final s in slots) _SlotCell(slot: s, item: game.equipped[s]),
        ],
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  final Slot slot;
  final Equipment? item;
  const _SlotCell({required this.slot, required this.item});
  @override
  Widget build(BuildContext context) {
    final rarity = item?.rarity;
    return GestureDetector(
      onTap: item == null
          ? null
          : () => showDialog(
                context: context,
                builder: (_) => _ItemDialog(item: item!),
              ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2a1d12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: rarity?.color ?? const Color(0xFF6a4a2a),
            width: 2.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(slot.emoji,
                style: TextStyle(
                    fontSize: 22,
                    color: item == null ? Colors.white24 : null)),
            if (item != null)
              Positioned(
                left: 2,
                bottom: 1,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: rarity!.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Lv${item!.level}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemDialog extends StatelessWidget {
  final Equipment item;
  const _ItemDialog({required this.item});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2a1d12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: item.rarity.color, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item.rarity.label} · ${item.slot.label}',
                style: TextStyle(
                    color: item.rarity.color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${item.slot.emoji} ${item.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Lv.${item.level}',
                style: const TextStyle(color: Colors.white54)),
            const Divider(color: Colors.white24, height: 20),
            for (final e in item.stats.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.label,
                        style: const TextStyle(color: Colors.white70)),
                    Text('+${e.value}',
                        style: const TextStyle(
                            color: Color(0xFF69F0AE),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 하단 네비 ─────────────────────────
class _NavBar extends StatelessWidget {
  const _NavBar();
  @override
  Widget build(BuildContext context) {
    const items = [
      ['👑', '외관'],
      ['🎒', '상점'],
      ['⚔️', 'PvP 레이드'],
      ['👼', '보스'],
      ['🛡️', '랭크'],
    ];
    return Container(
      color: const Color(0xFF4a3525),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++)
            _NavItem(
                emoji: items[i][0], label: items[i][1], active: i == 2),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool active;
  const _NavItem(
      {required this.emoji, required this.label, this.active = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6abf3a) : const Color(0xFF5a4332),
            shape: BoxShape.circle,
            border: Border.all(
                color: active ? const Color(0xFF9ee85a) : const Color(0xFF7a5a3a),
                width: 2),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
