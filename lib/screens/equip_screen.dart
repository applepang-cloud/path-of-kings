import 'package:flutter/material.dart';
import '../models.dart';
import '../game_state.dart';
import '../ui_kit.dart';

class EquipScreen extends StatefulWidget {
  final GameState game;
  const EquipScreen({super.key, required this.game});

  @override
  State<EquipScreen> createState() => _EquipScreenState();
}

class _EquipScreenState extends State<EquipScreen> {
  Equipment? selected;

  GameState get game => widget.game;

  bool get _isInInventory =>
      selected != null && game.inventory.contains(selected);

  bool get _isEquipped =>
      selected != null && game.equipped.values.contains(selected);

  /// 선택 아이템이 더 이상 존재하지 않으면 정리
  void _validateSelection() {
    if (selected == null) return;
    if (!game.inventory.contains(selected) &&
        !game.equipped.values.contains(selected)) {
      selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    _validateSelection();
    return MetaScaffold(
      title: '장비',
      emoji: '⚔️',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 재화 표시
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              CurrencyChip(emoji: '💰', value: game.gold, color: kGold),
              CurrencyChip(emoji: '💎', value: game.gems, color: kGreen),
              CurrencyChip(
                  emoji: '🔨',
                  value: game.enhanceStone,
                  color: const Color(0xFFFFAB91)),
              CurrencyChip(
                  emoji: '🌟',
                  value: game.evoStone,
                  color: const Color(0xFFCE93D8)),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              children: [
                const SectionTitle('장착 중'),
                _buildEquippedGrid(),
                const SectionTitle('가방'),
                _buildInventoryGrid(),
                if (selected != null) ...[
                  const SectionTitle('상세 / 액션'),
                  _buildDetail(),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedGrid() {
    final slots = Slot.values;
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final s in slots)
          ItemTile(
            item: game.equipped[s],
            emptySlot: s,
            selected: selected != null &&
                identical(selected, game.equipped[s]) &&
                game.equipped[s] != null,
            onTap: () {
              final eq = game.equipped[s];
              setState(() {
                selected = eq;
              });
            },
          ),
      ],
    );
  }

  Widget _buildInventoryGrid() {
    if (game.inventory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: panelDeco(),
        alignment: Alignment.center,
        child: const Text('가방이 비어 있습니다.',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
      );
    }
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final e in game.inventory)
          ItemTile(
            item: e,
            selected: identical(selected, e),
            onTap: () {
              setState(() {
                selected = e;
              });
            },
          ),
      ],
    );
  }

  Widget _buildDetail() {
    final item = selected!;
    final compare = game.equipped[item.slot];
    final inInventory = _isInInventory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EquipmentCardView(
          item: item,
          compareTo: _isEquipped ? null : compare,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildActionButtons(item, inInventory),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(Equipment item, bool inInventory) {
    final buttons = <Widget>[];

    // 장착
    if (inInventory) {
      buttons.add(GameButton(
        label: '장착',
        icon: Icons.shield_moon,
        color: const Color(0xFF3a7bd5),
        onTap: () {
          game.equipFromInventory(item);
          setState(() {});
          gameToast(context, '${item.name} 장착!', color: kGreen);
        },
      ));
    }

    // 강화 (골드)
    final toLevel = item.enhanceLevel + 1;
    final canEnhanceMore = item.enhanceLevel < item.maxEnhance;
    final goldCost = canEnhanceMore ? enhanceCost(item, item.enhanceLevel) : 0;
    final needStone = toLevel >= 10;
    final canGold = canEnhanceMore &&
        game.gold >= goldCost &&
        (!needStone || game.enhanceStone >= 1);
    final ratePct = (enhanceBaseRate(toLevel) * 100).round();
    buttons.add(GameButton(
      label: canEnhanceMore ? '강화 +$toLevel' : '강화 최대',
      sub: canEnhanceMore
          ? '${fmtNum(goldCost)}G${needStone ? ' +🔨1' : ''} · $ratePct%'
          : 'MAX',
      icon: Icons.upgrade,
      color: const Color(0xFF6abf3a),
      onTap: canGold
          ? () {
              final ok = game.enhanceWithGold(item);
              setState(() {});
              if (ok) {
                gameToast(context, '강화 성공! +${item.enhanceLevel}',
                    color: kGreen);
              } else {
                gameToast(context, '강화 실패...', color: kRed);
              }
            }
          : null,
    ));

    // 확정 강화 (젬) — +10 이상에서만
    if (canEnhanceMore && toLevel >= 10) {
      final gemCost = enhanceGemCost(toLevel);
      final canGem = game.gems >= gemCost && game.gold >= goldCost;
      buttons.add(GameButton(
        label: '확정강화 +$toLevel',
        sub: '$gemCost💎',
        icon: Icons.verified,
        color: const Color(0xFF26a69a),
        onTap: canGem
            ? () {
                final ok = game.enhanceWithGem(item);
                setState(() {});
                if (ok) {
                  gameToast(context, '확정 강화 성공! +${item.enhanceLevel}',
                      color: kGreen);
                } else {
                  gameToast(context, '재화 부족', color: kRed);
                }
              }
            : null,
      ));
    }

    // 부옵션 리롤
    if (item.subs.isNotEmpty) {
      final canReroll = game.gold >= GameState.rerollCost;
      buttons.add(GameButton(
        label: '부옵션 리롤',
        sub: '${fmtNum(GameState.rerollCost)}G',
        icon: Icons.casino,
        color: const Color(0xFF8d6e63),
        onTap: canReroll
            ? () {
                final ok = game.rerollSubs(item);
                setState(() {});
                gameToast(context, ok ? '부옵션 재추첨 완료!' : '골드 부족',
                    color: ok ? kGreen : kRed);
              }
            : null,
      ));
    }

    // 합성 3→1 (인벤토리 아이템 + 동등급/동부위 3개 이상)
    if (inInventory) {
      final mats = game.fusableMaterials(item.slot, item.rarity);
      if (game.canFuse(item.slot, item.rarity)) {
        // fuse()와 동일한 비용 산정(상위 3개 sellPrice 합 * 30%)
        final sorted = [...mats]..sort((a, b) => b.power.compareTo(a.power));
        final use = sorted.take(3).toList();
        final fuseCost =
            (use.fold<int>(0, (s, e) => s + e.sellPrice) * 0.30).round();
        final canPay = game.gold >= fuseCost;
        buttons.add(GameButton(
          label: '합성 3→1',
          sub: '재료 ${mats.length}개 · ${fmtNum(fuseCost)}G',
          icon: Icons.merge_type,
          color: const Color(0xFFab47bc),
          onTap: canPay
              ? () {
                  final result = game.fuse(item.slot, item.rarity);
                  setState(() => selected = result);
                  gameToast(
                      context,
                      result != null
                          ? '합성 성공! ${result.rarity.label} ${result.name}'
                          : '합성 실패',
                      color: result != null ? kGreen : kRed);
                }
              : null,
        ));
      }
    }

    // 진화 (만강 + 동급동부위1 + 진화석)
    if (game.canEvolve(item)) {
      final next = item.rarity.next;
      buttons.add(GameButton(
        label: '진화 →${next?.label ?? ''}',
        sub: '🌟${item.rarity.evolveStones}',
        icon: Icons.auto_awesome,
        color: const Color(0xFFff7043),
        onTap: () {
          final result = game.evolve(item);
          setState(() {
            selected = result;
          });
          gameToast(
              context,
              result != null
                  ? '진화 성공! ${result.rarity.label} ${result.name}'
                  : '진화 실패',
              color: result != null ? kGreen : kRed);
        },
      ));
    }

    // 판매 (인벤토리 아이템만)
    if (inInventory) {
      buttons.add(GameButton(
        label: '판매',
        sub: '+${fmtNum(item.sellPrice)}G',
        icon: Icons.sell,
        color: const Color(0xFFc62828),
        onTap: () {
          final price = item.sellPrice;
          game.sellFromInventory(item);
          setState(() {
            selected = null;
          });
          gameToast(context, '판매 완료 +${fmtNum(price)}G', color: kGold);
        },
      ));
    }

    return buttons;
  }
}
