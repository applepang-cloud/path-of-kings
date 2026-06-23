import 'package:flutter/material.dart';
import 'models.dart';
import 'game_state.dart';
import 'ui_kit.dart';

/// 새 장비 획득 — 2개 중 1개를 좌우 슬라이드로 선택
/// 왼쪽 = 판매(골드), 오른쪽 = 장착
class LootOverlay extends StatefulWidget {
  final GameState game;
  final List<Equipment> choices;
  const LootOverlay({super.key, required this.game, required this.choices});

  @override
  State<LootOverlay> createState() => _LootOverlayState();
}

class _LootOverlayState extends State<LootOverlay> {
  int index = 0;
  double drag = 0;
  bool decided = false;

  Equipment get current => widget.choices[index];

  void _onDragUpdate(DragUpdateDetails d) {
    if (decided) return;
    setState(() => drag += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    if (decided) return;
    const threshold = 90.0;
    if (drag > threshold) {
      _decide(equip: true);
    } else if (drag < -threshold) {
      _decide(equip: false);
    } else {
      setState(() => drag = 0);
    }
  }

  void _decide({required bool equip}) {
    setState(() => decided = true);
    final item = current;
    Future.delayed(const Duration(milliseconds: 180), () {
      if (equip) {
        widget.game.equipLoot(item);
      } else {
        widget.game.sellLoot(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.choices[1 - index];
    final equipped = widget.game.equipped[current.slot];

    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Text('새 장비 획득!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 8,
                    child: _SideLabel(
                      title: '판매',
                      sub: '+${current.sellPrice}🪙',
                      icon: Icons.arrow_back,
                      active: drag < -30,
                      color: const Color(0xFFFFB300),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: _SideLabel(
                      title: '장착',
                      sub: current.slot.label,
                      icon: Icons.arrow_forward,
                      active: drag > 30,
                      color: const Color(0xFF43A047),
                    ),
                  ),
                  GestureDetector(
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    child: AnimatedContainer(
                      duration: decided
                          ? const Duration(milliseconds: 180)
                          : Duration.zero,
                      transform: Matrix4.identity()
                        ..translateByDouble(
                            decided ? (drag > 0 ? 500.0 : -500.0) : drag,
                            0.0,
                            0.0,
                            1.0)
                        ..rotateZ(drag * 0.0008),
                      child: Container(
                        width: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: current.rarity.color.withValues(
                                  alpha: drag.abs() > 30 ? 0.9 : 0.4),
                              blurRadius: drag.abs() > 30 ? 30 : 14,
                              spreadRadius: drag.abs() > 30 ? 4 : 1,
                            ),
                          ],
                        ),
                        child: EquipmentCardView(
                            item: current, compareTo: equipped),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!decided)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => setState(() {
                            index = 1 - index;
                            drag = 0;
                          }),
                          icon: const Icon(Icons.swap_horiz,
                              color: Colors.white, size: 26),
                        ),
                        Text('다른 후보 (${index + 1}/2)',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    _MiniPreview(item: other),
                    const SizedBox(height: 6),
                    const Text('← 밀어서 판매    |    장착하려면 밀기 →',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const Text('슬라이드로 선택',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideLabel extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final bool active;
  final Color color;
  const _SideLabel(
      {required this.title,
      required this.sub,
      required this.icon,
      required this.active,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: active ? 1 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: active ? 36 : 28),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: active ? 20 : 16)),
          Text(sub, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  final Equipment item;
  const _MiniPreview({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.rarity.color, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(item.slot.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text('${item.rarity.label} ${item.name}',
            style: TextStyle(
                color: item.rarity.color,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(width: 6),
        Text('iLv${item.itemLevel} ⚔️${item.power}',
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}
