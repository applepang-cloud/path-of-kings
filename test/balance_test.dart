import 'package:flutter_test/flutter_test.dart';
import 'package:path_of_kings/game_state.dart';
import 'package:path_of_kings/models.dart';

/// 장비 선택 정책에 따라 게임을 자동으로 끝까지 시뮬레이션
class SimResult {
  final int deaths;
  final int bestProgress;
  SimResult(this.deaths, this.bestProgress);
  @override
  String toString() => 'deaths=$deaths, bestProgress=$bestProgress';
}

SimResult simulate({required bool smart, int ticks = 40000}) {
  final g = GameState();
  for (int i = 0; i < ticks; i++) {
    g.tick(0.05);
    if (g.phase == Phase.loot && g.lootChoices.length == 2) {
      if (!smart) {
        // 멍청한 선택: 무조건 판매(장비를 절대 안 낌)
        g.sellLoot(g.lootChoices.first);
      } else {
        // 똑똑한 선택: 현재 장착품보다 강한 후보가 있으면 장착, 아니면 판매
        final a = g.lootChoices[0];
        final b = g.lootChoices[1];
        int gain(Equipment e) =>
            e.power - (g.equipped[e.slot]?.power ?? 0);
        final best = gain(a) >= gain(b) ? a : b;
        if (gain(best) > 0) {
          g.equipLoot(best);
        } else {
          g.sellLoot(best);
        }
      }
    }
  }
  return SimResult(g.deaths, g.bestProgress);
}

void main() {
  test('장비를 안 끼면(잘못 고르면) 자동 전투에서 죽는다', () {
    final dumb = simulate(smart: false);
    // ignore: avoid_print
    print('멍청한 플레이어(항상 판매): $dumb');
    expect(dumb.deaths, greaterThan(0),
        reason: '장비 없이도 안 죽으면 안 됨 — 패배가 가능해야 한다');
  });

  test('장비를 잘 고르면 훨씬 멀리 진행하고 덜 죽는다', () {
    final dumb = simulate(smart: false);
    final smart = simulate(smart: true);
    // ignore: avoid_print
    print('멍청: $dumb  /  똑똑: $smart');
    expect(smart.bestProgress, greaterThan(dumb.bestProgress),
        reason: '장비를 잘 끼면 더 멀리 가야 한다');
    expect(smart.deaths, lessThanOrEqualTo(dumb.deaths),
        reason: '장비를 잘 끼면 덜 죽어야 한다');
  });
}
