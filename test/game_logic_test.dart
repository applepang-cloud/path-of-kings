import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_of_kings/game_state.dart';
import 'package:path_of_kings/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('전진 후 몬스터가 등장하고 전투 단계로 진입한다', () {
    final g = GameState();
    expect(g.phase, Phase.walking);
    for (int i = 0; i < 100 && g.phase == Phase.walking; i++) {
      g.tick(0.05);
    }
    expect(g.monster, isNotNull);
  });

  test('전투를 돌리면 골드를 얻고 진행한다', () {
    final g = GameState();
    final startGold = g.gold;
    bool sawCombat = false, gotReward = false;
    for (int i = 0; i < 4000; i++) {
      g.tick(0.05);
      if (g.phase == Phase.combat) sawCombat = true;
      if (g.gold > startGold) gotReward = true;
      if (g.phase == Phase.loot && g.lootChoices.isNotEmpty) {
        g.equipLoot(g.lootChoices.first);
      }
    }
    expect(sawCombat, isTrue);
    expect(gotReward, isTrue);
    expect(g.progress, greaterThan(0));
  });

  test('장비 장착 시 전투력과 피해가 증가한다', () {
    final g = GameState();
    final basePower = g.power;
    final baseDmg = g.damage;
    final weapon = Equipment.generate(20, forceSlot: Slot.weapon);
    g.equipLoot(weapon);
    expect(g.equipped[Slot.weapon], weapon);
    expect(g.power, greaterThan(basePower));
    expect(g.damage, greaterThan(baseDmg));
  });

  test('판매하면 골드가 늘고 장착되지 않는다', () {
    final g = GameState();
    final item = Equipment.generate(10, forceSlot: Slot.ring);
    final before = g.gold;
    g.sellLoot(item);
    expect(g.gold, before + item.sellPrice);
    expect(g.equipped[Slot.ring], isNull);
  });

  test('등급이 높을수록 평균 전투력이 높다', () {
    int avg(Rarity r) {
      int t = 0;
      for (int i = 0; i < 200; i++) {
        t += Equipment.generate(20, forceSlot: Slot.weapon, forceRarity: r)
            .power;
      }
      return t ~/ 200;
    }

    expect(avg(Rarity.legendary), greaterThan(avg(Rarity.common)));
    expect(avg(Rarity.rare), greaterThan(avg(Rarity.uncommon)));
  });

  test('강화하면 메인스탯과 전투력이 오른다(상한 존재)', () {
    final g = GameState();
    g.gold = 100000000;
    g.enhanceStone = 1000;
    final item = Equipment.generate(20, forceSlot: Slot.weapon,
        forceRarity: Rarity.legendary);
    g.inventory.add(item);
    final base = item.power;
    int tries = 0;
    while (item.enhanceLevel < item.maxEnhance && tries < 500) {
      g.enhanceWithGold(item);
      tries++;
    }
    expect(item.enhanceLevel, item.maxEnhance);
    expect(item.power, greaterThan(base));
    // 상한 초과 강화 불가
    expect(g.enhanceWithGold(item), isFalse);
  });

  test('판매가는 강화로 오르지 않는다(차익 차단)', () {
    final item = Equipment.generate(20, forceSlot: Slot.armor,
        forceRarity: Rarity.rare);
    final before = item.sellPrice;
    item.enhanceLevel = 5;
    expect(item.sellPrice, before);
  });

  test('합성: 동등급·동부위 3개 → 1개', () {
    final g = GameState();
    g.gold = 100000;
    for (int i = 0; i < 3; i++) {
      g.inventory.add(Equipment.generate(15,
          forceSlot: Slot.helmet, forceRarity: Rarity.uncommon));
    }
    expect(g.canFuse(Slot.helmet, Rarity.uncommon), isTrue);
    final result = g.fuse(Slot.helmet, Rarity.uncommon);
    expect(result, isNotNull);
    expect(result!.rarity, Rarity.uncommon);
    expect(g.fusableMaterials(Slot.helmet, Rarity.uncommon).length, 1);
  });

  test('진화: 만강 영웅 + 동급 1개 + 진화석 → 전설', () {
    final g = GameState();
    g.evoStone = 100;
    final maxed = Equipment.generate(30, forceSlot: Slot.ring,
        forceRarity: Rarity.epic);
    maxed.enhanceLevel = maxed.maxEnhance;
    final partner = Equipment.generate(30, forceSlot: Slot.ring,
        forceRarity: Rarity.epic);
    g.inventory.addAll([maxed, partner]);
    expect(g.canEvolve(maxed), isTrue);
    final evolved = g.evolve(maxed);
    expect(evolved, isNotNull);
    expect(evolved!.rarity, Rarity.legendary);
  });

  test('가챠는 젬을 소모하고 인벤토리에 적재한다', () {
    final g = GameState();
    g.gems = 1000;
    final before = g.inventory.length;
    final r = g.gacha(10);
    expect(r.length, 10);
    expect(g.gems, 100); // 900 소모
    expect(g.inventory.length, before + 10);
  });

  test('강화 pity(실패 누적)가 세이브/로드 후 보존된다', () async {
    final g = GameState();
    final item = Equipment.generate(20, forceSlot: Slot.ring,
        forceRarity: Rarity.epic);
    item.enhanceFailStreak = 4;
    g.equipped[Slot.ring] = item;
    await g.save();
    final g2 = GameState();
    await g2.load();
    expect(g2.equipped[Slot.ring]?.enhanceFailStreak, 4);
  });

  test('세이브→로드 후 상태가 보존된다', () async {
    final g = GameState();
    g.gold = 12345;
    g.gems = 67;
    g.level = 9;
    g.zone = 3;
    g.equipLoot(Equipment.generate(20, forceSlot: Slot.weapon));
    await g.save();

    final g2 = GameState();
    await g2.load();
    expect(g2.gold, 12345);
    expect(g2.gems, 67);
    expect(g2.level, 9);
    expect(g2.equipped[Slot.weapon], isNotNull);
  });
}
