import 'package:flutter/material.dart';
import '../game_state.dart';
import '../ui_kit.dart';

class RankScreen extends StatelessWidget {
  final GameState game;
  const RankScreen({super.key, required this.game});

  // 티어별 색상
  static const List<Color> _tierColors = [
    Color(0xFFB08D57), // 브론즈
    Color(0xFFC0C0C0), // 실버
    Color(0xFFFFD54F), // 골드
    Color(0xFF66E0E0), // 플래티넘
    Color(0xFFFF6FB5), // 챔피언
  ];

  static const List<String> _tierReq = [
    '전투력 ~399',
    '전투력 400~1199',
    '전투력 1200~2999',
    '전투력 3000~7999',
    '전투력 8000+',
  ];

  static const List<int> _tierCoinPerHour = [10, 25, 45, 70, 100];

  @override
  Widget build(BuildContext context) {
    final tier = game.rankTier;
    final tierColor = _tierColors[tier];

    return MetaScaffold(
      title: '랭크',
      emoji: '🏅',
      child: ListView(
        children: [
          // ── 1) 현재 티어 ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tierColor.withValues(alpha: 0.55),
                  tierColor.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tierColor, width: 2.5),
            ),
            child: Column(
              children: [
                const Text('현재 랭크',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(GameState.rankNames[tier],
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 6)
                      ],
                    )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚔️ 내 전투력  ',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(fmtNum(game.power),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 2) 랭크코인 보유/획득 ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: panelDeco(),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('보유 랭크코인',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    CurrencyChip(
                        emoji: '🏅', value: game.rankCoin, color: kGold),
                  ],
                ),
                const Divider(color: kBorder, height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('시간당 획득',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    Text('+${game.rankCoinPerHour} / 시간',
                        style: const TextStyle(
                            color: kGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPanelBg2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text('⏳ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          '랭크코인은 현재 티어에 따라 자동으로 누적됩니다. 게임을 꺼둔 동안(오프라인)에도 계속 쌓여요.',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                              height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 3) 티어 사다리 ──
          const SectionTitle('티어 사다리'),
          Container(
            decoration: panelDeco(),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // 헤더
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 78,
                          child: Text('티어',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11))),
                      Expanded(
                          child: Text('필요 전투력',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11))),
                      Text('코인/시간',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                const Divider(color: kBorder, height: 8),
                // 챔피언이 위로 오도록 역순 표시
                for (int t = GameState.rankNames.length - 1; t >= 0; t--)
                  _tierRow(t, tier),
              ],
            ),
          ),

          // ── 4) 랭크코인 용도 ──
          const SectionTitle('랭크 상점'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: panelDeco(border: kBorder),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('🏪 ', style: TextStyle(fontSize: 16)),
                    Text('랭크코인 사용처',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                _useItem('💎', '진화석 교환', '고등급 장비 승급에 필요한 진화석'),
                _useItem('🪨', '강화석 교환', '+10 이상 강화에 필요한 강화석'),
                _useItem('🎨', '외관(스킨)', '무기·갑옷 외형 커스터마이즈'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: kPanelBg2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder, width: 1.5),
                  ),
                  child: const Text('🚧 랭크 상점은 준비 중입니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kGold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tierRow(int t, int current) {
    final isCurrent = t == current;
    final c = _tierColors[t];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? c.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? c : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    GameState.rankNames[t],
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white70,
                      fontSize: 13.5,
                      fontWeight:
                          isCurrent ? FontWeight.w900 : FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(_tierReq[t],
                style: const TextStyle(
                    color: Colors.white60, fontSize: 11.5)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏅', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 2),
              Text('${_tierCoinPerHour[t]}/h',
                  style: TextStyle(
                      color: isCurrent ? kGold : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          if (isCurrent) ...[
            const SizedBox(width: 6),
            const Text('●',
                style: TextStyle(color: kGreen, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _useItem(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
