import 'package:flutter/material.dart';
import '../game_state.dart';
import '../ui_kit.dart';

class PvpScreen extends StatelessWidget {
  final GameState game;
  const PvpScreen({super.key, required this.game});

  void _fight(BuildContext context) {
    if (game.pvpLeft <= 0) {
      gameToast(context, '오늘의 대전 횟수를 모두 사용했어요', color: kRed);
      return;
    }
    final win = game.pvp();
    showDialog<void>(
      context: context,
      builder: (ctx) => _ResultDialog(win: win, game: game),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tier = game.rankTier;
    final tierName = GameState.rankNames[tier];
    final canFight = game.pvpLeft > 0;

    return MetaScaffold(
      title: '아레나 대전',
      emoji: '⚔️',
      child: ListView(
        children: [
          // ── 상단 요약 ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: panelDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Text('⚔️', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('내 전투력',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                          Text(fmtNum(game.power),
                              style: const TextStyle(
                                  color: kGold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20)),
                        ],
                      ),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPanelBg2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorder, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('현재 티어',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                          Text(tierName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CurrencyChip(
                        emoji: '🏆', value: game.pvpPoints, color: kGreen),
                    CurrencyChip(
                        emoji: '🎖️', value: game.arenaCoin, color: kGold),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPanelBg2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder, width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('🔁', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 3),
                        Text('${game.pvpLeft}/5',
                            style: TextStyle(
                                color:
                                    game.pvpLeft > 0 ? Colors.white : kRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SectionTitle('대전'),

          // ── 매칭 연출 안내 ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: panelDeco(bg: kPanelBg2),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _fighterFace('🧑‍🚀', '나', kGold),
                    const Text('VS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                    _fighterFace('👹', '도전자', kRed),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    '상대 전투력은 내 전투력의 0.85~1.15배 범위에서 매칭됩니다.\n'
                    '(예상 상대 전투력 약 ${fmtNum((game.power * 0.85).round())} ~ ${fmtNum((game.power * 1.15).round())})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 대전 시작 버튼 ──
          GameButton(
            label: '대전 시작',
            sub: canFight
                ? '남은 횟수 ${game.pvpLeft}/5'
                : '오늘 횟수 소진 (자정 초기화)',
            icon: Icons.sports_kabaddi,
            color: canFight ? kRed : const Color(0xFF555555),
            onTap: canFight ? () => _fight(context) : null,
          ),

          if (!canFight)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('오늘의 대전 횟수를 모두 사용했어요. 매일 자정에 5회로 초기화됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),

          const SectionTitle('티어 안내'),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: panelDeco(),
            child: Column(
              children: [
                for (int i = 0; i < GameState.rankNames.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: i == tier
                          ? kGold.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: i == tier ? kGold : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text(_tierEmoji(i),
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(GameState.rankNames[i],
                              style: TextStyle(
                                  color: i == tier
                                      ? kGold
                                      : Colors.white70,
                                  fontWeight: i == tier
                                      ? FontWeight.w900
                                      : FontWeight.normal,
                                  fontSize: 14)),
                        ]),
                        Text(_tierRange(i),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
                '티어는 전투력으로 결정됩니다. 전투력을 올려 더 높은 티어에 도전하세요.\n'
                '승리 시 PvP 점수 +20, 패배 시 -10 (최소 0). 점수로 시즌 순위가 정해집니다.',
                style: TextStyle(
                    color: Colors.white60, fontSize: 12, height: 1.4)),
          ),

          const SectionTitle('아레나 코인 🎖️'),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: panelDeco(bg: kPanelBg2),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('대전에서 승리하면 아레나 코인을 30~80개 획득합니다.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12.5, height: 1.4)),
                SizedBox(height: 6),
                Text('• 부옵션 리롤권 교환 (준비중)',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                Text('• 한정 외관/스킨 교환 (준비중)',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                SizedBox(height: 8),
                Text('아레나 상점은 곧 열립니다. 코인을 미리 모아두세요!',
                    style: TextStyle(
                        color: kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _fighterFace(String emoji, String label, Color c) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kPanelBg,
            shape: BoxShape.circle,
            border: Border.all(color: c, width: 2.5),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: c, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  static String _tierEmoji(int i) =>
      const ['🥉', '🥈', '🥇', '💎', '👑'][i];

  static String _tierRange(int i) => const [
        '전투력 < 400',
        '400 ~ 1.2K',
        '1.2K ~ 3K',
        '3K ~ 8K',
        '8K 이상',
      ][i];
}

class _ResultDialog extends StatelessWidget {
  final bool win;
  final GameState game;
  const _ResultDialog({required this.win, required this.game});

  @override
  Widget build(BuildContext context) {
    final c = win ? kGreen : kRed;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c, width: 2.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(win ? '🎉' : '😢', style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 6),
            Text(win ? '승리!' : '패배...',
                style: TextStyle(
                    color: c, fontWeight: FontWeight.w900, fontSize: 26)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPanelBg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder, width: 1.5),
              ),
              child: Column(
                children: [
                  if (win) ...[
                    const Text('아레나 코인을 획득했습니다!',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CurrencyChip(
                            emoji: '🎖️',
                            value: game.arenaCoin,
                            color: kGold),
                        const SizedBox(width: 8),
                        CurrencyChip(
                            emoji: '🏆',
                            value: game.pvpPoints,
                            color: kGreen),
                      ],
                    ),
                  ] else ...[
                    const Text('PvP 점수가 소폭 감소했습니다.',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    CurrencyChip(
                        emoji: '🏆',
                        value: game.pvpPoints,
                        color: kGreen),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('남은 대전 ${game.pvpLeft}/5',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 14),
            GameButton(
              label: '확인',
              color: c,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
