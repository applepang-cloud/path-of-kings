import 'package:flutter/material.dart';
import '../game_state.dart';
import '../ui_kit.dart';

class BossScreen extends StatelessWidget {
  final GameState game;
  const BossScreen({super.key, required this.game});

  void _challenge(BuildContext context) {
    final w = game.bossRush();
    if (w == -1) {
      gameToast(context, '오늘 도전 횟수를 모두 사용했어요', color: kRed);
      return;
    }
    final cleared = w > 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: panelDeco(border: kGold, width: 2.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cleared ? '☠️🐲☠️' : '💀',
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(cleared ? '$w웨이브 클리어!' : '돌파 실패',
                    style: TextStyle(
                        color: cleared ? kGold : kRed,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
                const SizedBox(height: 4),
                Text(cleared ? '보상 획득!' : '전투력이 부족해 한 웨이브도 넘지 못했어요',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: panelDeco(bg: kPanelBg2, width: 1.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _rewardRow('🎫 보스토큰', game.bossToken),
                      const SizedBox(height: 6),
                      _rewardRow('🔨 강화석', game.enhanceStone),
                      const SizedBox(height: 6),
                      _rewardRow('🌟 진화석', game.evoStone),
                      const SizedBox(height: 6),
                      _rewardRow('🪙 골드', game.gold, color: kGold),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GameButton(
                  label: '확인',
                  color: kGreen,
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rewardRow(String label, int value, {Color color = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text('현재 ${fmtNum(value)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = game.bossRushLeft;
    final canChallenge = left > 0;

    return MetaScaffold(
      title: '보스 러시',
      emoji: '☠️',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 보스 비주얼 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3a1414), Color(0xFF1c0e0e)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kRed, width: 2),
              ),
              child: const Column(
                children: [
                  Text('🐲', style: TextStyle(fontSize: 54)),
                  SizedBox(height: 6),
                  Text('보스 러시',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                  Text('☠️ 끝없는 보스의 물결을 돌파하라 ☠️',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),

            const SectionTitle('도전 정보'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: panelDeco(),
              child: Column(
                children: [
                  _infoRow('⚔️ 현재 전투력', fmtNum(game.power), color: kGold),
                  const Divider(color: kBorder, height: 16),
                  _infoRow('🗡️ 일일 도전', '$left / 3',
                      color: canChallenge ? kGreen : kRed),
                  const Divider(color: kBorder, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('보유 보스토큰',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13.5)),
                      CurrencyChip(
                          emoji: '🎫',
                          value: game.bossToken,
                          color: const Color(0xFFFFB74D)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            GameButton(
              label: '보스 러시 도전',
              sub: canChallenge ? '남은 횟수 $left회' : '오늘 도전 완료',
              icon: Icons.local_fire_department,
              color: kRed,
              onTap: canChallenge ? () => _challenge(context) : null,
            ),

            const SectionTitle('안내'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: panelDeco(bg: kPanelBg2),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• 전투력이 높을수록 더 많은 웨이브를 클리어합니다.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5)),
                  SizedBox(height: 6),
                  Text('• 클리어한 웨이브에 따라 보스토큰·강화석·진화석·골드를 획득합니다.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5)),
                  SizedBox(height: 6),
                  Text('• 모은 보스토큰으로 보스상점을 이용할 수 있어요. (준비중)',
                      style: TextStyle(
                          color: Color(0xFFB39DDB),
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color color = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
