import 'dart:async';
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'ui_kit.dart';
import 'screens/adventure_screen.dart';
import 'screens/equip_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/boss_screen.dart';
import 'screens/pvp_screen.dart';
import 'screens/rank_screen.dart';

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
      home: const GameRoot(),
    );
  }
}

class GameRoot extends StatefulWidget {
  const GameRoot({super.key});
  @override
  State<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<GameRoot> with WidgetsBindingObserver {
  final game = GameState();
  Timer? _timer;
  Duration _last = Duration.zero;
  final _stopwatch = Stopwatch();
  int tab = 0;
  bool _offlineShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stopwatch.start();
    game.load().then((_) => _maybeShowOffline());
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final now = _stopwatch.elapsed;
      double dt = (now - _last).inMicroseconds / 1e6;
      _last = now;
      if (dt > 0.1) dt = 0.1;
      game.tick(dt);
    });
  }

  void _maybeShowOffline() {
    if (_offlineShown || game.pendingOffline == null) return;
    _offlineShown = true;
    final o = game.pendingOffline!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => _OfflineDialog(game: game, reward: o),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      game.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      game.onResumed();
      _offlineShown = false; // 복귀 시 방치보상 다이얼로그 재표출 허용
      _maybeShowOffline();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    game.save();
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
                Expanded(
                  child: IndexedStack(
                    index: tab,
                    children: [
                      AdventureScreen(
                          game: game, onOpenEquip: () => setState(() => tab = 1)),
                      EquipScreen(game: game),
                      ShopScreen(game: game),
                      BossScreen(game: game),
                      PvpScreen(game: game),
                      RankScreen(game: game),
                    ],
                  ),
                ),
                _BottomNav(
                    index: tab, onTap: (i) => setState(() => tab = i)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameState game;
  const _TopBar({required this.game});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: kPanelBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CurrencyChip(emoji: '🪙', value: game.gold, color: kGold),
          CurrencyChip(
              emoji: '💎', value: game.gems, color: const Color(0xFF4FC3F7)),
          CurrencyChip(
              emoji: '🔨',
              value: game.enhanceStone,
              color: const Color(0xFFB0BEC5)),
          CurrencyChip(
              emoji: '🔮',
              value: game.evoStone,
              color: const Color(0xFFCE93D8)),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    const items = [
      ['🏃', '모험'],
      ['⚔️', '장비'],
      ['🛒', '상점'],
      ['☠️', '보스'],
      ['🆚', 'PvP'],
      ['🏅', '랭크'],
    ];
    return Container(
      color: const Color(0xFF4a3525),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++)
            GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index
                          ? const Color(0xFF6abf3a)
                          : const Color(0xFF5a4332),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: i == index
                              ? const Color(0xFF9ee85a)
                              : kBorder,
                          width: 2),
                    ),
                    child: Text(items[i][0],
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 2),
                  Text(items[i][1],
                      style: TextStyle(
                          color: i == index ? Colors.white : Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OfflineDialog extends StatelessWidget {
  final GameState game;
  final OfflineReward reward;
  const _OfflineDialog({required this.game, required this.reward});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kPanelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kGold, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌙 방치 보상',
                style: TextStyle(
                    color: kGold,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${fmtDuration(reward.seconds)} 동안 모험했어요!',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Divider(color: Colors.white24, height: 20),
            _row('🪙 골드', reward.gold),
            _row('✨ 경험치', reward.xp),
            if (reward.stones > 0) _row('🔨 강화석', reward.stones),
            if (reward.evoStones > 0) _row('🔮 진화석', reward.evoStones),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameButton(
                  label: '받기',
                  color: const Color(0xFF6abf3a),
                  onTap: () {
                    game.clearOffline();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                GameButton(
                  label: '광고로 2배',
                  icon: Icons.play_circle_fill,
                  color: const Color(0xFFE69138),
                  onTap: () {
                    game.doubleOffline();
                    final o = game.pendingOffline;
                    game.clearOffline();
                    Navigator.pop(context);
                    if (o != null) {
                      gameToast(context, '🪙 골드 2배 획득! +${fmtNum(o.gold)}',
                          color: const Color(0xFFE69138));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text('+${fmtNum(v)}',
                style: const TextStyle(
                    color: kGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
}
