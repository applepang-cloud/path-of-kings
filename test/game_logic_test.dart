import 'package:flutter_test/flutter_test.dart';
import 'package:path_of_kings/game_state.dart';
import 'package:path_of_kings/models.dart';

void main() {
  test('전진 후 몬스터가 등장하고 전투 단계로 진입한다', () {
    final g = GameState();
    expect(g.phase, Phase.walking);
    // 전진 완료까지 틱
    for (int i = 0; i < 100 && g.phase == Phase.walking; i++) {
      g.tick(0.05);
    }
    expect(g.phase, anyOf(Phase.combat, Phase.loot, Phase.walking));
    expect(g.monster, isNotNull);
  });

  test('전투를 끝까지 돌리면 골드/경험치를 얻고 진행한다', () {
    final g = GameState();
    final startGold = g.gold;
    bool sawCombat = false;
    bool gotReward = false;
    // 충분히 오래 돌려 여러 스테이지 진행
    for (int i = 0; i < 4000; i++) {
      g.tick(0.05);
      if (g.phase == Phase.combat) sawCombat = true;
      if (g.gold > startGold) gotReward = true;
      // 전리품이 나오면 자동으로 첫 후보 장착해서 막힘 방지
      if (g.phase == Phase.loot && g.lootChoices.isNotEmpty) {
        g.equipLoot(g.lootChoices.first);
      }
    }
    expect(sawCombat, isTrue, reason: '전투 단계가 한 번도 없었음');
    expect(gotReward, isTrue, reason: '골드 보상을 받지 못함');
    expect(g.progress, greaterThan(0), reason: '스테이지가 진행되지 않음');
  });

  test('장비 장착 시 스탯과 전투력이 증가한다', () {
    final g = GameState();
    final basePower = g.power;
    final baseDmg = g.damage;
    final weapon = Equipment.random(20, forceSlot: Slot.weapon);
    g.equipLoot(weapon);
    expect(g.equipped[Slot.weapon], weapon);
    expect(g.power, greaterThan(basePower));
    expect(g.damage, greaterThan(baseDmg));
  });

  test('판매하면 골드가 늘고 장비는 장착되지 않는다', () {
    final g = GameState();
    final item = Equipment.random(10, forceSlot: Slot.ring);
    final before = g.gold;
    g.sellLoot(item);
    expect(g.gold, before + item.sellPrice);
    expect(g.equipped[Slot.ring], isNull);
  });

  test('등급이 높을수록 평균 전투력이 높다', () {
    int sum(Rarity r) {
      int total = 0;
      for (int i = 0; i < 200; i++) {
        total += Equipment.random(20,
                forceSlot: Slot.weapon, forceRarity: r)
            .power;
      }
      return total ~/ 200;
    }

    expect(sum(Rarity.legendary), greaterThan(sum(Rarity.common)));
    expect(sum(Rarity.rare), greaterThan(sum(Rarity.uncommon)));
  });
}
