import 'package:flutter/material.dart';
import '../models.dart';
import '../game_state.dart';
import '../ui_kit.dart';

class ShopScreen extends StatefulWidget {
  final GameState game;
  const ShopScreen({super.key, required this.game});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  GameState get game => widget.game;

  void _doGacha(int count) {
    final cost = count == 10 ? 900 : 100;
    if (game.gems < cost) {
      gameToast(context, '젬이 부족합니다', color: kRed);
      return;
    }
    final results = game.gacha(count);
    if (results.isEmpty) {
      gameToast(context, '뽑기에 실패했습니다', color: kRed);
      return;
    }
    _showGachaResult(results);
  }

  void _showGachaResult(List<Equipment> results) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: kPanelBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kBorder, width: 2),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              maxWidth: 420,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '✨ 뽑기 결과 (${results.length})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          EquipmentCardView(item: results[i]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    label: '닫기',
                    color: kBorder,
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _buyEnhanceStone(int n, int cost) {
    if (game.buyEnhanceStone(n)) {
      gameToast(context, '강화석 ×$n 구매!', color: kGreen);
    } else {
      gameToast(context, '골드가 부족합니다', color: kRed);
    }
  }

  void _buyEvoStone() {
    if (game.buyEvoStone()) {
      gameToast(context, '진화석 ×1 구매!', color: kGreen);
    } else {
      gameToast(context, '구매할 수 없습니다 (한도/골드 확인)', color: kRed);
    }
  }

  void _buyOfflineCap() {
    if (game.buyOfflineCapExtend()) {
      gameToast(context, '방치 최대시간 +2h 적용!', color: kGreen);
    } else {
      gameToast(context, '젬이 부족합니다', color: kRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final evoSoldOut = game.shopEvoBought >= 5;
    final canBuyEvo = !evoSoldOut && game.gold >= 2000;

    return MetaScaffold(
      title: '상점',
      emoji: '🏪',
      child: ListView(
        children: [
          // 상단 재화
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CurrencyChip(emoji: '💰', value: game.gold, color: kGold),
              const SizedBox(width: 10),
              CurrencyChip(
                  emoji: '💎',
                  value: game.gems,
                  color: const Color(0xFF80D8FF)),
            ],
          ),

          // === 카드 뽑기 ===
          const SectionTitle('카드 뽑기'),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: panelDeco(),
            child: const Text(
              '등급 확률: 일반 55% · 고급 28% · 희귀 12% · 영웅 4% · 전설 1%\n'
              '• 50회마다 영웅 이상 확정 보장\n'
              '• 10연 뽑기는 희귀 이상 1개 보장',
              style: TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: '1회 뽑기',
                  sub: '100 💎',
                  color: const Color(0xFF5b6abf),
                  onTap: game.gems >= 100 ? () => _doGacha(1) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: '10연 뽑기',
                  sub: '900 💎',
                  color: const Color(0xFF8e44ad),
                  onTap: game.gems >= 900 ? () => _doGacha(10) : null,
                ),
              ),
            ],
          ),

          // === 골드 상점 ===
          const SectionTitle('골드 상점'),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: '강화석 ×1',
                  sub: '100 G',
                  color: const Color(0xFFbf8f3a),
                  onTap: game.gold >= 100
                      ? () => _buyEnhanceStone(1, 100)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: '강화석 ×10',
                  sub: '1000 G',
                  color: const Color(0xFFbf8f3a),
                  onTap: game.gold >= 1000
                      ? () => _buyEnhanceStone(10, 1000)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GameButton(
            label: '진화석 ×1',
            sub: '2000 G  (오늘 ${game.shopEvoBought}/5)',
            color: const Color(0xFF3a9fbf),
            onTap: canBuyEvo ? _buyEvoStone : null,
          ),
          if (evoSoldOut)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text('오늘 진화석을 모두 구매했습니다.',
                  style: TextStyle(color: kRed, fontSize: 11.5)),
            ),

          // === 젬 상점 ===
          const SectionTitle('젬 상점'),
          GameButton(
            label: '방치 보상 최대시간 +2h',
            sub: '800 💎',
            color: const Color(0xFF5b6abf),
            onTap: game.gems >= 800 ? _buyOfflineCap : null,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
