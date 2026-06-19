import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';

final _rng = Random();

enum Phase { walking, combat, loot, dying }

class GameState extends ChangeNotifier {
  // 재화 / 성장
  int gold = 0;
  int gems = 0;
  int level = 1;
  int xp = 0;

  // 진행
  int zone = 1;
  int stage = 1;
  static const int maxStage = 5;
  int get progress => (zone - 1) * maxStage + (stage - 1);

  // 기록
  int deaths = 0;
  int bestProgress = 0;

  // 전투 상태
  Phase phase = Phase.walking;
  double playerHp = 100;
  double walkProgress = 0; // 0..1 전진
  Monster? monster;
  double _playerCd = 0;
  double _monsterCd = 0;

  // 연출
  double shake = 0;
  double hitFlash = 0; // 몬스터 피격 깜빡임
  double slash = 0; // 칼 휘두름 애니
  final List<FloatingText> floaters = [];

  // 장비
  final Map<Slot, Equipment?> equipped = {for (final s in Slot.values) s: null};

  // 전리품 (2개 중 택1)
  List<Equipment> lootChoices = [];

  GameState() {
    playerHp = maxHp.toDouble();
  }

  // ---- 합산 스탯 ----
  int _sum(Stat s) {
    int base = switch (s) {
      Stat.hp => 100 + (level - 1) * 22,
      Stat.damage => 10 + (level - 1) * 3,
      Stat.accuracy => 10 + (level - 1) * 2,
      Stat.defense => 5 + (level - 1),
      Stat.lifesteal => 0,
    };
    for (final e in equipped.values) {
      if (e != null) base += e.stats[s] ?? 0;
    }
    return base;
  }

  int get maxHp => _sum(Stat.hp);
  int get damage => _sum(Stat.damage);
  int get accuracy => _sum(Stat.accuracy);
  int get defense => _sum(Stat.defense);
  int get lifesteal => _sum(Stat.lifesteal);

  int get power {
    int p = ((maxHp) / 5).round() +
        damage * 2 +
        accuracy +
        defense +
        lifesteal * 3;
    return p;
  }

  int get xpNeeded => 50 + level * level * 6;

  String get zoneLabel => '구역 $zone-$stage';

  // ---- 게임 루프 ----
  void tick(double dt) {
    // 연출 감쇠
    if (shake > 0) shake = max(0, shake - dt * 6);
    if (hitFlash > 0) hitFlash = max(0, hitFlash - dt * 5);
    if (slash > 0) slash = max(0, slash - dt * 4);
    for (final f in floaters) {
      f.life -= dt;
    }
    floaters.removeWhere((f) => f.life <= 0);

    switch (phase) {
      case Phase.walking:
        // 전진 중 소량 자연 회복 (전투 사이 숨 고르기, 완전 회복은 안 됨)
        if (playerHp < maxHp) {
          playerHp = min(maxHp.toDouble(), playerHp + maxHp * 0.04 * dt);
        }
        walkProgress += dt / 1.1;
        if (walkProgress >= 1) {
          _spawnMonster();
        }
        break;
      case Phase.combat:
        _combat(dt);
        break;
      case Phase.dying:
        // 잠깐 멈췄다가 부활
        _playerCd -= dt;
        if (_playerCd <= 0) _respawn();
        break;
      case Phase.loot:
        break; // 일시정지 (선택 대기)
    }
    notifyListeners();
  }

  void _spawnMonster() {
    walkProgress = 1;
    final boss = stage == maxStage;
    monster = Monster.spawn(progress, boss: boss);
    phase = Phase.combat;
    _playerCd = 0.4;
    _monsterCd = 0.9;
  }

  void _combat(double dt) {
    final m = monster!;
    _playerCd -= dt;
    _monsterCd -= dt;

    if (_playerCd <= 0) {
      _playerCd = 0.6;
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
    final critChance = accuracy / (accuracy + 220);
    final isCrit = _rng.nextDouble() < critChance;
    double dmg = damage * (0.85 + _rng.nextDouble() * 0.3);
    if (isCrit) dmg *= 2;
    m.hp -= dmg;
    hitFlash = 1;
    shake = isCrit ? 1.0 : 0.4;
    floaters.add(FloatingText(
      dmg.round().toString(),
      isCrit ? const Color(0xFFFFEB3B) : Colors.white,
      Offset(0.52 + _rng.nextDouble() * 0.1, 0.34),
      size: isCrit ? 34 : 24,
    ));
    if (lifesteal > 0 && playerHp < maxHp) {
      playerHp = min(maxHp.toDouble(), playerHp + lifesteal);
    }
    if (m.hp <= 0) _onKill(m);
  }

  void _monsterAttack(Monster m) {
    final taken = max(1.0, m.damage - defense * 0.4);
    playerHp -= taken;
    shake = 0.5;
    floaters.add(FloatingText(
      '-${taken.round()}',
      const Color(0xFFFF5252),
      const Offset(0.30, 0.62),
      size: 20,
    ));
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
    gold += m.goldReward;
    xp += m.xpReward;
    floaters.add(FloatingText('+${m.goldReward}G', const Color(0xFFFFD54F),
        const Offset(0.46, 0.5),
        size: 22, maxLife: 1.1));
    if (m.isBoss) {
      gems += 5;
    }
    _checkLevelUp();

    // 드랍 판정
    final dropChance = m.isBoss ? 1.0 : 0.38;
    if (_rng.nextDouble() < dropChance) {
      _generateLoot(m.isBoss);
      phase = Phase.loot; // 선택 대기
    } else {
      _advance();
    }
  }

  void _checkLevelUp() {
    while (xp >= xpNeeded) {
      xp -= xpNeeded;
      level++;
      // 레벨업 시 절반만 회복 (완전 회복 아님 → 누적 피해가 위협됨)
      playerHp = min(maxHp.toDouble(), playerHp + maxHp * 0.5);
      floaters.add(FloatingText('LEVEL UP! Lv.$level', const Color(0xFF69F0AE),
          const Offset(0.34, 0.4),
          size: 26, maxLife: 1.4));
    }
  }

  void _generateLoot(bool boss) {
    final pl = progress + level;
    final a = Equipment.random(pl,
        forceRarity: boss ? _bossRarity() : null);
    // 두 번째는 같은 부위로 (비교 재미) 또는 랜덤
    final b = _rng.nextBool()
        ? Equipment.random(pl, forceSlot: a.slot)
        : Equipment.random(pl);
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
    // 패널티: 골드 15% 상실 + 한 스테이지 후퇴
    // → 장비가 약하면 같은 구간에서 반복 사망(진행 벽)하게 됨
    gold = (gold * 0.85).round();
    if (stage > 1) {
      stage--;
    } else if (zone > 1) {
      zone--;
      stage = maxStage - 1;
    }
    floaters.add(FloatingText('💀 후퇴! (-15% 골드)', const Color(0xFFFF8A80),
        const Offset(0.30, 0.5),
        size: 22, maxLife: 1.4));
    playerHp = maxHp.toDouble();
    monster = null;
    walkProgress = 0;
    phase = Phase.walking;
  }

  // ---- 전리품 선택 (UI에서 호출) ----
  void equipLoot(Equipment e) {
    equipped[e.slot] = e;
    floaters.add(FloatingText('${e.slot.label} 장착!', e.rarity.color,
        const Offset(0.34, 0.42),
        size: 24, maxLife: 1.2));
    lootChoices = [];
    _advance();
    notifyListeners();
  }

  void sellLoot(Equipment e) {
    gold += e.sellPrice;
    floaters.add(FloatingText('+${e.sellPrice}G (판매)', const Color(0xFFFFD54F),
        const Offset(0.36, 0.45),
        size: 22, maxLife: 1.1));
    lootChoices = [];
    _advance();
    notifyListeners();
  }
}
