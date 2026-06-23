import 'package:flutter/material.dart';
import '../models.dart';
import '../game_state.dart';
import '../ui_kit.dart';
import '../scene.dart';
import '../loot_overlay.dart';

/// 모험(자동 전투) 화면
class AdventureScreen extends StatelessWidget {
  final GameState game;
  final VoidCallback onOpenEquip;
  const AdventureScreen(
      {super.key, required this.game, required this.onOpenEquip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 구역 라벨
        Container(
          color: kPanelBg,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: kPanelBg2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder, width: 2),
              ),
              child: Text(game.zoneLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: SceneView(game: game)),
              if (game.phase == Phase.loot && game.lootChoices.length == 2)
                Positioned.fill(
                  child: LootOverlay(game: game, choices: game.lootChoices),
                ),
            ],
          ),
        ),
        _PlayerBar(game: game),
        _EquipmentGrid(game: game, onOpenEquip: onOpenEquip),
      ],
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final GameState game;
  const _PlayerBar({required this.game});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPanelBg,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
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
                  Text('⚔️ 전투력 ${fmtNum(game.power)}',
                      style: const TextStyle(
                          color: kGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (game.deaths > 0)
                    Text('💀 ${game.deaths}',
                        style: const TextStyle(
                            color: Color(0xFFFF8A80), fontSize: 11)),
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

class _EquipmentGrid extends StatelessWidget {
  final GameState game;
  final VoidCallback onOpenEquip;
  const _EquipmentGrid({required this.game, required this.onOpenEquip});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPanelBg2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final s in Slot.values)
                ItemTile(
                    item: game.equipped[s],
                    emptySlot: s,
                    onTap: onOpenEquip),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onOpenEquip,
            child: const Text('🔧 장비 관리 / 강화',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
