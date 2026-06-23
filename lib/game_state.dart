import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

final _rng = Random();

enum Phase { walking, combat, loot, dying }

class OfflineReward {
  final int seconds, gold, xp, stones, evoStones;
  OfflineReward(this.seconds, this.gold, this.xp, this.stones, this.evoStones);
}

class GameState extends ChangeNotifier {
  // ---- 재화 ----
  int gold = 0;
  int gems = 0;
  int enhanceStone = 0;
  int evoStone = 0;
  int bossToken = 0;
  int arenaCoin = 0;
  int rankCoin = 0;

  // ---- 성장 ----
  int level = 1;
  int xp = 0;

  // ---- 진행 ----
  int zone = 1;
  int stage = 1;
  static const int maxStage = 5;
  int get progress => (zone - 1) * maxStage + (stage - 1);

  int deaths = 0;
  int bestProgress = 0;
  final Set<int> clearedBossZones = {};

  // ---- 전투 상태 ----
  Phase phase = Phase.walking;
  double playerHp = 100;
  double walkProgress = 0;
  Monster? monster;
  double _playerCd = 0;
  double _monsterCd = 0;
  double _clock = 0;
  double _monsterSpawnClock = 0;

  // 흡혈 초당 회복 예산
  double _healBudget = 0;
  double _healSecAcc = 0;

  // 방치보상용 처치 통계(일반몹, 현재 최고 구역)
  double avgKillTime = 4.0;
  double avgKillGold = 10.0;
  int _avgKillZone = 0;

  // ---- 연출 ----
  double shake = 0;
  double hitFlash = 0;
  double slash = 0;
  final List<FloatingText> floaters = [];

  // ---- 장비 ----
  final Map<Slot, Equipment?> equipped = {for (final s in Slot.values) s: null};
  final List<Equipment> inventory = [];
  static const int invMax = 60;

  // 전리품
  List<Equipment> lootChoices = [];

  // 랭크코인 온라인 누적 잔여
  double _rankAcc = 0;

  // ---- 메타: 일일/시간 ----
  int bossRushLeft = 3;
  int pvpLeft = 5;
  int shopEvoBought = 0; // 일일 진화석 구매
  String _lastDaily = '';
  int pvpPoints = 0;
  int gachaPityEpic = 0; // 누적 뽑기(영웅↑ 천장)
  int offlineCapBonusH = 0; // 젬으로 구매한 캡 연장

  // ---- 저장/시간 ----
  bool loaded = false;
  int _lastSeenMs = 0;
  int _lastRankMs = 0;
  OfflineReward? pendingOffline;
  double _saveTimer = 0;

  GameState() {
    playerHp = maxHp.toDouble();
    _healBudget = maxHp * 0.08;
  }

  // ───────── 합산 스탯 ─────────
  double _mainTotal(Stat s) {
    double v = 0;
    for (final e in equipped.values) {
      if (e != null) v += e.effMain(s);
    }
    return v;
  }

  double _subTotal(Stat s) {
    double v = 0;
    for (final e in equipped.values) {
      if (e != null) v += e.sub(s);
    }
    return v;
  }

  int get maxHp => (100 + (level - 1) * 22 + _mainTotal(Stat.hp)).round();
  int get damage => (10 + (level - 1) * 3 + _mainTotal(Stat.damage)).round();
  int get accuracy => (10 + (level - 1) * 2 + _mainTotal(Stat.accuracy)).round();
  int get defense => (5 + (level - 1) + _mainTotal(Stat.defense)).round();

  double get critChanceSum => _subTotal(Stat.critChance);
  double get critDamageSum => _subTotal(Stat.critDamage);
  double get penSum => _subTotal(Stat.penetration);
  double get dodgeSum => _subTotal(Stat.dodge);
  double get attackSpeedSum => _subTotal(Stat.attackSpeed);
  double get lifestealSum => _subTotal(Stat.lifesteal);
  double get goldFindSum => _subTotal(Stat.goldFind);

  // 전투 파생치
  double get critRate => min(
      0.60, accuracy / (accuracy + 220 + 18 * progress) + critChanceSum / 100);
  double get critMult => 1.6 + critDamageSum;
  double get attackInterval =>
      max(0.3, 0.6 / (1 + 0.5 * min(60, attackSpeedSum) / 100));
  double get dodgeChance => min(60, dodgeSum) / 100;
  double get penFactor => min(100, penSum) / 100;
  double get goldFindMult => 1 + min(150, goldFindSum) / 100;

  int get power {
    double p = maxHp / 5 + damage * 2 + accuracy + defense.toDouble();
    // 전투력은 전투에서 실제 적용되는 캡과 동일하게 계산(PvP/랭크 왜곡 방지)
    p += critChanceSum * 2 +
        critDamageSum * 100 +
        min(100, penSum) * 2 +
        min(60, dodgeSum) * 2 +
        min(60, attackSpeedSum) * 4 +
        lifestealSum * 3;
    return p.round();
  }

  int get xpNeeded => 50 + level * level * 6;
  String get zoneLabel => '구역 $zone-$stage';

  // ───────── 게임 루프 ─────────
  void tick(double dt) {
    _clock += dt;
    if (shake > 0) shake = max(0, shake - dt * 6);
    if (hitFlash > 0) hitFlash = max(0, hitFlash - dt * 5);
    if (slash > 0) slash = max(0, slash - dt * 4);
    for (final f in floaters) {
      f.life -= dt;
    }
    floaters.removeWhere((f) => f.life <= 0);

    // 흡혈 예산 리필
    _healSecAcc += dt;
    if (_healSecAcc >= 1) {
      _healSecAcc = 0;
      _healBudget = maxHp * 0.08;
    }

    // 랭크코인 온라인 자동 축적
    _rankAcc += rankCoinPerHour * dt / 3600;
    if (_rankAcc >= 1) {
      final n = _rankAcc.floor();
      rankCoin += n;
      _rankAcc -= n;
    }
    // 주기 저장
    _saveTimer += dt;
    if (_saveTimer >= 30) {
      _saveTimer = 0;
      save();
    }

    switch (phase) {
      case Phase.walking:
        if (playerHp < maxHp) {
          playerHp = min(maxHp.toDouble(), playerHp + maxHp * 0.04 * dt);
        }
        walkProgress += dt / 1.1;
        if (walkProgress >= 1) _spawnMonster();
        break;
      case Phase.combat:
        _combat(dt);
        break;
      case Phase.dying:
        _playerCd -= dt;
        if (_playerCd <= 0) _respawn();
        break;
      case Phase.loot:
        break;
    }
    notifyListeners();
  }

  void _spawnMonster() {
    walkProgress = 1;
    final boss = stage == maxStage;
    monster = Monster.spawn(progress, boss: boss);
    _monsterSpawnClock = _clock;
    phase = Phase.combat;
    _playerCd = 0.3;
    _monsterCd = 0.9;
  }

  void _combat(double dt) {
    final m = monster!;
    _playerCd -= dt;
    _monsterCd -= dt;
    if (_playerCd <= 0) {
      _playerCd = attackInterval;
      _playerAttack(m);
    }
    if (m.hp <= 0) return;
    if (_monsterCd <= 0) {
      _monsterCd = 0.95;
      _monsterAttack(m);
    }
  }

  void _playerAttack(Monster m) {
    slash = 1;
    final isCrit = _rng.nextDouble() < critRate;
    double dmg = damage * (0.85 + _rng.nextDouble() * 0.3);
    if (isCrit) dmg *= critMult;
    // 적 방어 + 관통
    final effDef = m.defense * (1 - penFactor);
    final dealt = dmg * 100 / (100 + effDef);
    m.hp -= dealt;
    hitFlash = 1;
    shake = isCrit ? 1.0 : 0.4;
    floaters.add(FloatingText(
      dealt.round().toString(),
      isCrit ? const Color(0xFFFFEB3B) : Colors.white,
      Offset(0.52 + _rng.nextDouble() * 0.1, 0.34),
      size: isCrit ? 34 : 24,
    ));
    // 흡혈(가한 피해 비례, 단타 30% + 초당 maxHp 8% 캡)
    if (lifestealSum > 0 && playerHp < maxHp) {
      double heal = dealt * (lifestealSum / 100);
      heal = min(heal, dealt * 0.30);
      heal = min(heal, _healBudget);
      if (heal > 0) {
        playerHp = min(maxHp.toDouble(), playerHp + heal);
        _healBudget -= heal;
      }
    }
    if (m.hp <= 0) _onKill(m);
  }

  void _monsterAttack(Monster m) {
    if (_rng.nextDouble() < dodgeChance) {
      floaters.add(FloatingText('MISS', const Color(0xFF80D8FF),
          const Offset(0.30, 0.6),
          size: 18));
      return;
    }
    final taken = max(1.0, m.damage - defense * 0.45);
    playerHp -= taken;
    shake = 0.5;
    floaters.add(FloatingText('-${taken.round()}', const Color(0xFFFF5252),
        const Offset(0.30, 0.62),
        size: 20));
    if (playerHp <= 0) {
      playerHp = 0;
      phase = Phase.dying;
      _playerCd = 1.3;
      floaters.add(FloatingText('패배...', Colors.redAccent,
          const Offset(0.42, 0.45),
          size: 30, maxLife: 1.3));
    }
  }

  void _onKill(Monster m) {
    final goldGain = (m.goldReward * goldFindMult).round();
    gold += goldGain;
    xp += m.xpReward;
    floaters.add(FloatingText('+${goldGain}G', const Color(0xFFFFD54F),
        const Offset(0.46, 0.5),
        size: 22, maxLife: 1.1));

    // 처치 통계(일반몹, 현재 최고 구역만) — goldFind 미적용 원본 골드로 기록
    // (방치보상 산정에 goldFind가 새지 않도록)
    if (!m.isBoss) {
      final baseGold = m.goldReward.toDouble();
      if (zone > _avgKillZone) {
        _avgKillZone = zone;
        avgKillTime = max(1.0, _clock - _monsterSpawnClock);
        avgKillGold = baseGold;
      } else if (zone == _avgKillZone) {
        final t = max(1.0, _clock - _monsterSpawnClock);
        avgKillTime = avgKillTime * 0.7 + t * 0.3;
        avgKillGold = avgKillGold * 0.7 + baseGold * 0.3;
      }
    }

    _checkLevelUp();

    final firstClear = m.isBoss && !clearedBossZones.contains(zone);
    if (m.isBoss) {
      if (firstClear) {
        clearedBossZones.add(zone);
        gems += 5;
        final es = 1 + _rng.nextInt(2);
        evoStone += es;
        floaters.add(FloatingText('보스 격파! +5💎 +$es 진화석',
            const Color(0xFF69F0AE), const Offset(0.30, 0.4),
            size: 22, maxLife: 1.5));
      }
    }

    // 드랍
    final double dropChance = m.isBoss ? (firstClear ? 1.0 : 0.15) : 0.38;
    if (_rng.nextDouble() < dropChance) {
      _generateLoot(boss: m.isBoss && firstClear);
      phase = Phase.loot;
    } else {
      _advance();
    }
  }

  void _checkLevelUp() {
    while (xp >= xpNeeded) {
      xp -= xpNeeded;
      level++;
      playerHp = min(maxHp.toDouble(), playerHp + maxHp * 0.5);
      floaters.add(FloatingText('LEVEL UP! Lv.$level', const Color(0xFF69F0AE),
          const Offset(0.34, 0.4),
          size: 26, maxLife: 1.4));
    }
  }

  void _generateLoot({bool boss = false}) {
    final iLv = max(1, progress + level + _rng.nextInt(3) - 1);
    final a = Equipment.generate(iLv,
        forceRarity: boss ? _bossRarity() : null);
    final b = _rng.nextBool()
        ? Equipment.generate(iLv, forceSlot: a.slot)
        : Equipment.generate(iLv);
    lootChoices = [a, b];
  }

  Rarity _bossRarity() {
    final r = _rng.nextDouble();
    if (r < 0.4) return Rarity.rare;
    if (r < 0.8) return Rarity.epic;
    return Rarity.legendary;
  }

  void _advance() {
    monster = null;
    walkProgress = 0;
    phase = Phase.walking;
    if (stage >= maxStage) {
      stage = 1;
      zone++;
    } else {
      stage++;
    }
    if (progress > bestProgress) bestProgress = progress;
  }

  void _respawn() {
    deaths++;
    gold = (gold * 0.85).round();
    stage = 1; // 같은 구역 1스테이지로 후퇴(보스 재팜 방지)
    floaters.add(FloatingText('💀 후퇴! (-15% 골드)', const Color(0xFFFF8A80),
        const Offset(0.30, 0.5),
        size: 22, maxLife: 1.4));
    playerHp = maxHp.toDouble();
    monster = null;
    walkProgress = 0;
    phase = Phase.walking;
  }

  // ───────── 전리품 선택 ─────────
  void equipLoot(Equipment e) {
    _equip(e);
    floaters.add(FloatingText('${e.slot.label} 장착!', e.rarity.color,
        const Offset(0.34, 0.42),
        size: 24, maxLife: 1.2));
    lootChoices = [];
    _advance();
    save();
    notifyListeners();
  }

  void sellLoot(Equipment e) {
    gold += e.sellPrice;
    floaters.add(FloatingText('+${e.sellPrice}G (판매)', const Color(0xFFFFD54F),
        const Offset(0.36, 0.45),
        size: 22, maxLife: 1.1));
    lootChoices = [];
    _advance();
    save();
    notifyListeners();
  }

  /// 장착(기존 장비는 인벤토리로)
  void _equip(Equipment e) {
    final old = equipped[e.slot];
    equipped[e.slot] = e;
    inventory.remove(e);
    if (old != null) _addToInventory(old);
  }

  void equipFromInventory(Equipment e) {
    _equip(e);
    save();
    notifyListeners();
  }

  void _addToInventory(Equipment e) {
    inventory.add(e);
    if (inventory.length > invMax) {
      // 가장 약한 것 자동 판매
      inventory.sort((a, b) => a.power.compareTo(b.power));
      final junk = inventory.removeAt(0);
      gold += junk.sellPrice;
    }
  }

  void sellFromInventory(Equipment e) {
    if (inventory.remove(e)) {
      gold += e.sellPrice;
      save();
      notifyListeners();
    }
  }

  // ───────── 강화 ─────────
  /// 골드 강화. 성공 여부 반환
  bool enhanceWithGold(Equipment e) {
    if (e.enhanceLevel >= e.maxEnhance) return false;
    final to = e.enhanceLevel + 1;
    final cost = enhanceCost(e, e.enhanceLevel);
    if (gold < cost) return false;
    // +10 이상은 강화석 1개 추가 소모
    final needStone = to >= 10;
    if (needStone && enhanceStone < 1) return false;
    if (needStone) enhanceStone--;
    gold -= cost;
    final rate =
        (enhanceBaseRate(to) + e.enhanceFailStreak * 0.05).clamp(0.0, 1.0);
    if (_rng.nextDouble() < rate) {
      e.enhanceLevel = to;
      e.enhanceFailStreak = 0;
      _epicSubBonus(e);
      save();
      notifyListeners();
      return true;
    } else {
      e.enhanceFailStreak++;
      save();
      notifyListeners();
      return false;
    }
  }

  /// 젬 확정 강화
  bool enhanceWithGem(Equipment e) {
    if (e.enhanceLevel >= e.maxEnhance) return false;
    final to = e.enhanceLevel + 1;
    final gemCost = enhanceGemCost(to);
    final goldC = enhanceCost(e, e.enhanceLevel);
    if (gems < gemCost || gold < goldC) return false;
    gems -= gemCost;
    gold -= goldC;
    e.enhanceLevel = to;
    e.enhanceFailStreak = 0;
    _epicSubBonus(e);
    save();
    notifyListeners();
    return true;
  }

  /// 영웅 등급 +6/+12 도달 시 부옵션 추가(최대 3)
  void _epicSubBonus(Equipment e) {
    if (e.rarity != Rarity.epic) return;
    if ((e.enhanceLevel == 6 || e.enhanceLevel == 12) && e.subs.length < 3) {
      final pool = subAffixPool.where((s) => !e.subs.containsKey(s)).toList();
      if (pool.isNotEmpty) {
        final pick = pool[_rng.nextInt(pool.length)];
        e.subs[pick] = Equipment.generate(1, forceRarity: e.rarity).subs[pick] ??
            (e.rarity.mult * 2);
        // 안전: 범위 기반 재생성
        final tmp = Equipment.generate(e.itemLevel, forceRarity: e.rarity);
        e.subs[pick] = tmp.subs[pick] ?? e.subs[pick]!;
      }
    }
  }

  /// 부옵션 리롤 (5000골드)
  static const int rerollCost = 5000;
  bool rerollSubs(Equipment e) {
    if (e.subs.isEmpty || gold < rerollCost) return false;
    gold -= rerollCost;
    e.rerollSubs();
    save();
    notifyListeners();
    return true;
  }

  // ───────── 합성(동등급·동부위 3개 → 1) ─────────
  List<Equipment> fusableMaterials(Slot slot, Rarity rarity) =>
      inventory.where((e) => e.slot == slot && e.rarity == rarity).toList();

  bool canFuse(Slot slot, Rarity rarity) =>
      fusableMaterials(slot, rarity).length >= 3;

  Equipment? fuse(Slot slot, Rarity rarity) {
    final mats = fusableMaterials(slot, rarity);
    if (mats.length < 3) return null;
    mats.sort((a, b) => b.power.compareTo(a.power));
    final use = mats.take(3).toList();
    final cost = (use.fold<int>(0, (s, e) => s + e.sellPrice) * 0.30).round();
    if (gold < cost) return null;
    gold -= cost;
    final maxLv = use.map((e) => e.itemLevel).reduce(max);
    final best = use.first;
    final result = Equipment(
      slot: slot,
      rarity: rarity,
      itemLevel: maxLv,
      name: best.name,
      // 재료 best 메인스탯을 하한으로 보장(합성이 손해가 되지 않게)
      main: {
        for (final st in slotMainStats[slot]!)
          st: max(_mainBase[st]! * maxLv * rarity.mult * 1.1,
              best.main[st] ?? 0).roundToDouble()
      },
      subs: Map.of(best.subs),
      enhanceLevel: use.map((e) => e.enhanceLevel).reduce(min), // 최저값 계승
    );
    for (final e in use) {
      inventory.remove(e);
    }
    _addToInventory(result);
    save();
    notifyListeners();
    return result;
  }

  static const _mainBase = {
    Stat.hp: 12.0,
    Stat.damage: 2.2,
    Stat.accuracy: 3.0,
    Stat.defense: 2.0,
  };

  // ───────── 진화(승급) ─────────
  /// 만강 재료 1 + 임의 동등급/동부위 1 + 진화석
  bool canEvolve(Equipment maxed) {
    if (maxed.rarity.next == null) return false;
    if (maxed.enhanceLevel < maxed.maxEnhance) return false;
    final partner = inventory.firstWhere(
      (e) => e != maxed && e.slot == maxed.slot && e.rarity == maxed.rarity,
      orElse: () => maxed,
    );
    if (partner == maxed) return false;
    return evoStone >= maxed.rarity.evolveStones;
  }

  Equipment? evolve(Equipment maxed) {
    if (!canEvolve(maxed)) return null;
    final newRarity = maxed.rarity.next!;
    final partner = inventory.firstWhere(
        (e) => e != maxed && e.slot == maxed.slot && e.rarity == maxed.rarity);
    evoStone -= maxed.rarity.evolveStones;
    final avgLv = ((maxed.itemLevel + partner.itemLevel) / 2).round();
    final bonusLv = max(2, (newRarity.enhanceMax * 0.3).round());
    final newLv = avgLv + bonusLv;
    final inheritEnhance =
        (maxed.enhanceLevel * newRarity.enhanceMax / maxed.maxEnhance * 0.5)
            .round();
    final result = Equipment(
      slot: maxed.slot,
      rarity: newRarity,
      itemLevel: newLv,
      name: Equipment.generate(newLv, forceSlot: maxed.slot, forceRarity: newRarity)
          .name,
      main: {
        for (final st in slotMainStats[maxed.slot]!)
          st: (_mainBase[st]! * newLv * newRarity.mult).roundToDouble()
      },
      subs: Equipment.generate(newLv, forceSlot: maxed.slot, forceRarity: newRarity)
          .subs,
      enhanceLevel: inheritEnhance.clamp(0, newRarity.enhanceMax),
    );
    // 재료 소비: 장착 중이면 해제
    if (equipped[maxed.slot] == maxed) equipped[maxed.slot] = null;
    inventory.remove(maxed);
    inventory.remove(partner);
    _addToInventory(result);
    save();
    notifyListeners();
    return result;
  }

  // ───────── 상점 ─────────
  bool buyEnhanceStone(int n) {
    final cost = 100 * n;
    if (gold < cost) return false;
    gold -= cost;
    enhanceStone += n;
    save();
    notifyListeners();
    return true;
  }

  bool buyEvoStone() {
    if (shopEvoBought >= 5 || gold < 2000) return false;
    gold -= 2000;
    evoStone++;
    shopEvoBought++;
    save();
    notifyListeners();
    return true;
  }

  bool buyOfflineCapExtend() {
    final zoneBonus =
        (bestProgress >= 20 ? 2 : 0) + (bestProgress >= 45 ? 2 : 0);
    final currentCap = (8 + offlineCapBonusH + zoneBonus).clamp(8, 24);
    if (gems < 800 || currentCap >= 24) return false; // 24h 상한 도달 시 무효 구매 차단
    gems -= 800;
    offlineCapBonusH += 2;
    save();
    notifyListeners();
    return true;
  }

  // ───────── 카드 뽑기 ─────────
  Rarity _gachaRarity() {
    final r = _rng.nextDouble();
    if (r < 0.55) return Rarity.common;
    if (r < 0.83) return Rarity.uncommon;
    if (r < 0.95) return Rarity.rare;
    if (r < 0.99) return Rarity.epic;
    return Rarity.legendary;
  }

  List<Equipment> gacha(int count) {
    final cost = count == 10 ? 900 : 100 * count;
    if (gems < cost) return [];
    gems -= cost;
    final results = <Equipment>[];
    bool gotRarePlus = false;
    for (int i = 0; i < count; i++) {
      gachaPityEpic++;
      Rarity r = _gachaRarity();
      if (gachaPityEpic >= 50 && r.index < Rarity.epic.index) {
        r = Rarity.epic;
      }
      if (r.index >= Rarity.epic.index) gachaPityEpic = 0;
      if (r.index >= Rarity.rare.index) gotRarePlus = true;
      results.add(Equipment.generate(progress + level, forceRarity: r));
    }
    // 10연 희귀↑ 보장
    if (count == 10 && !gotRarePlus) {
      results[results.length - 1] =
          Equipment.generate(progress + level, forceRarity: Rarity.rare);
    }
    for (final e in results) {
      _addToInventory(e);
    }
    save();
    notifyListeners();
    return results;
  }

  // ───────── 보스 러시 ─────────
  /// 결과: 클리어한 웨이브 수
  int bossRush() {
    if (bossRushLeft <= 0) return -1;
    bossRushLeft--;
    final reqPerWave = 80 * (1 + bestProgress * 0.4);
    int waves = (power / reqPerWave).floor().clamp(0, 10);
    if (waves > 0) {
      bossToken += 10 + waves * 2;
      enhanceStone += 3 + waves;
      if (_rng.nextDouble() < 0.3 + waves * 0.05) evoStone++;
      gold += (waves * 200 * (1 + bestProgress * 0.1)).round();
    }
    save();
    notifyListeners();
    return waves;
  }

  // ───────── PvP ─────────
  /// 결과: true=승
  bool pvp() {
    if (pvpLeft <= 0) return false;
    pvpLeft--;
    final oppPower = (power * (0.85 + _rng.nextDouble() * 0.30)).round();
    // 명중/회피, 관통/방어 약간 반영한 승률
    double winChance = power / (power + oppPower);
    winChance += (dodgeChance - 0.1) * 0.2;
    winChance = winChance.clamp(0.05, 0.95);
    final win = _rng.nextDouble() < winChance;
    if (win) {
      arenaCoin += 30 + _rng.nextInt(51);
      pvpPoints += 20;
    } else {
      pvpPoints = max(0, pvpPoints - 10);
    }
    save();
    notifyListeners();
    return win;
  }

  // ───────── 랭크 ─────────
  int get rankTier {
    final p = power;
    if (p < 400) return 0; // 브론즈
    if (p < 1200) return 1; // 실버
    if (p < 3000) return 2; // 골드
    if (p < 8000) return 3; // 플래티넘
    return 4; // 챔피언
  }

  static const rankNames = ['브론즈', '실버', '골드', '플래티넘', '챔피언'];
  int get rankCoinPerHour => const [10, 25, 45, 70, 100][rankTier];

  // ───────── 일일 리셋 ─────────
  void _checkDailyReset() {
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    if (_lastDaily != key) {
      _lastDaily = key;
      bossRushLeft = 3;
      pvpLeft = 5;
      shopEvoBought = 0;
    }
  }

  // ───────── 저장/로드 ─────────
  Map<String, dynamic> toJson() => {
        'v': 1,
        'gold': gold,
        'gems': gems,
        'enh': enhanceStone,
        'evo': evoStone,
        'btk': bossToken,
        'arena': arenaCoin,
        'rank': rankCoin,
        'level': level,
        'xp': xp,
        'zone': zone,
        'stage': stage,
        'deaths': deaths,
        'best': bestProgress,
        'bossZones': clearedBossZones.toList(),
        'hp': playerHp,
        'equipped': {
          for (final e in equipped.entries)
            if (e.value != null) e.key.index.toString(): e.value!.toJson()
        },
        'inv': inventory.map((e) => e.toJson()).toList(),
        'akt': avgKillTime,
        'akg': avgKillGold,
        'akz': _avgKillZone,
        'brl': bossRushLeft,
        'pvl': pvpLeft,
        'sev': shopEvoBought,
        'daily': _lastDaily,
        'pvp': pvpPoints,
        'pity': gachaPityEpic,
        'capH': offlineCapBonusH,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'lastRank': _lastRankMs,
      };

  Future<void> save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('pok_save', jsonEncode(toJson()));
    } catch (_) {}
  }

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString('pok_save');
      if (s != null) _fromJson(jsonDecode(s));
    } catch (_) {}
    _checkDailyReset();
    _computeOffline();
    _lastRankMs = DateTime.now().millisecondsSinceEpoch;
    loaded = true;
    playerHp = playerHp.clamp(1, maxHp.toDouble());
    _healBudget = maxHp * 0.08;
    notifyListeners();
  }

  void _fromJson(Map<String, dynamic> j) {
    gold = j['gold'] ?? 0;
    gems = j['gems'] ?? 0;
    enhanceStone = j['enh'] ?? 0;
    evoStone = j['evo'] ?? 0;
    bossToken = j['btk'] ?? 0;
    arenaCoin = j['arena'] ?? 0;
    rankCoin = j['rank'] ?? 0;
    level = j['level'] ?? 1;
    xp = j['xp'] ?? 0;
    zone = j['zone'] ?? 1;
    stage = j['stage'] ?? 1;
    deaths = j['deaths'] ?? 0;
    bestProgress = j['best'] ?? 0;
    clearedBossZones
      ..clear()
      ..addAll((j['bossZones'] as List?)?.map((e) => e as int) ?? []);
    playerHp = (j['hp'] ?? 100).toDouble();
    equipped.updateAll((k, v) => null);
    final eq = j['equipped'] as Map?;
    if (eq != null) {
      eq.forEach((k, v) {
        try {
          final si = int.tryParse(k.toString());
          if (si == null || si < 0 || si >= Slot.values.length) return;
          equipped[Slot.values[si]] =
              Equipment.fromJson(Map<String, dynamic>.from(v));
        } catch (_) {/* 손상된 아이템 1개는 건너뜀 */}
      });
    }
    inventory.clear();
    for (final e in (j['inv'] as List?) ?? const []) {
      try {
        inventory.add(Equipment.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {/* 손상된 아이템은 건너뜀 */}
    }
    avgKillTime = (j['akt'] ?? 4.0).toDouble();
    avgKillGold = (j['akg'] ?? 10.0).toDouble();
    _avgKillZone = j['akz'] ?? 0;
    bossRushLeft = j['brl'] ?? 3;
    pvpLeft = j['pvl'] ?? 5;
    shopEvoBought = j['sev'] ?? 0;
    _lastDaily = j['daily'] ?? '';
    pvpPoints = j['pvp'] ?? 0;
    gachaPityEpic = j['pity'] ?? 0;
    offlineCapBonusH = j['capH'] ?? 0;
    _lastSeenMs = j['lastSeen'] ?? 0;
    _lastRankMs = j['lastRank'] ?? 0;
  }

  void _computeOffline() {
    if (_lastSeenMs <= 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    int sec = ((now - _lastSeenMs) / 1000).floor();
    if (sec < 0) sec = 0; // 시계 조작 방지
    final capH = (8 + offlineCapBonusH +
            (bestProgress >= 20 ? 2 : 0) +
            (bestProgress >= 45 ? 2 : 0))
        .clamp(8, 24);
    sec = min(sec, capH * 3600);
    if (sec < 300) return; // 5분 미만 보상 없음(랭크코인 포함)
    // 랭크코인 누적(오프라인, 5분 이상)
    rankCoin += (sec / 3600 * rankCoinPerHour).floor();

    final tKill = max(1.0, avgKillTime);
    double onlineGoldPerSec = avgKillGold / tKill;
    final ceil = (10 * (1 + 0.30 * progress)) / 1.0;
    onlineGoldPerSec = min(onlineGoldPerSec, ceil);
    if (avgKillGold <= 10.0 && _avgKillZone == 0) {
      onlineGoldPerSec = (10 * (1 + 0.30 * progress)) / 4.0; // fallback
    }
    final onlineXpPerSec = onlineGoldPerSec * 0.8;

    final goldR = (onlineGoldPerSec * sec * 0.25).floor();
    final xpR = (onlineXpPerSec * sec * 0.25).floor();
    final stones = (sec / 3600 * (1 + progress * 0.05) * 0.5).floor();
    final evoR = (sec / 3600 * 0.15).floor();

    gold += goldR;
    xp += xpR;
    enhanceStone += stones;
    evoStone += evoR;
    _checkLevelUp();
    pendingOffline = OfflineReward(sec, goldR, xpR, stones, evoR);
  }

  /// 방치보상 광고 2배
  void doubleOffline() {
    final o = pendingOffline;
    if (o == null) return;
    gold += o.gold; // 광고 보상: 골드만 추가 1배(총 2배). 경험치/재화는 대상 아님
    pendingOffline =
        OfflineReward(o.seconds, o.gold * 2, o.xp, o.stones, o.evoStones);
    save();
    notifyListeners();
  }

  void clearOffline() {
    pendingOffline = null;
    save();
    notifyListeners();
  }

  // ───────── 앱 라이프사이클 ─────────
  /// 백그라운드 진입: 기준 시각 저장
  void onPaused() {
    _lastSeenMs = DateTime.now().millisecondsSinceEpoch;
    save();
  }

  /// 포그라운드 복귀: 자정 리셋 + 방치보상 재계산(디스크 재로드 없이 인메모리)
  void onResumed() {
    _checkDailyReset();
    _computeOffline(); // _lastSeenMs(직전 onPaused 시각) 기준
    _lastSeenMs = DateTime.now().millisecondsSinceEpoch; // 동일 구간 재계산 방지
    notifyListeners();
  }
}
