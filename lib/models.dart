import 'dart:math';
import 'package:flutter/material.dart';

final _rng = Random();

/// 장비 부위
enum Slot { weapon, offhand, helmet, armor, gloves, boots, amulet, ring, pet }

extension SlotInfo on Slot {
  String get label => const {
        Slot.weapon: '무기',
        Slot.offhand: '보조',
        Slot.helmet: '투구',
        Slot.armor: '갑옷',
        Slot.gloves: '장갑',
        Slot.boots: '신발',
        Slot.amulet: '목걸이',
        Slot.ring: '반지',
        Slot.pet: '펫',
      }[this]!;

  String get emoji => const {
        Slot.weapon: '🗡️',
        Slot.offhand: '🛡️',
        Slot.helmet: '🪖',
        Slot.armor: '🦺',
        Slot.gloves: '🧤',
        Slot.boots: '🥾',
        Slot.amulet: '📿',
        Slot.ring: '💍',
        Slot.pet: '🐾',
      }[this]!;
}

/// 스탯 종류 — flat 4종(메인) + 부옵션 7종
enum Stat {
  hp,
  damage,
  accuracy,
  defense,
  // 부옵션(%)
  critChance, // %p (정수 저장)
  critDamage, // 분수 저장(0.30 = +30%)
  penetration, // %
  dodge, // %
  attackSpeed, // %
  lifesteal, // %(가한 피해의 %)
  goldFind, // %
}

extension StatInfo on Stat {
  String get label => const {
        Stat.hp: '체력',
        Stat.damage: '피해',
        Stat.accuracy: '명중',
        Stat.defense: '방어력',
        Stat.critChance: '치명확률',
        Stat.critDamage: '치명피해',
        Stat.penetration: '방어관통',
        Stat.dodge: '회피',
        Stat.attackSpeed: '공격속도',
        Stat.lifesteal: '흡혈',
        Stat.goldFind: '골드획득',
      }[this]!;

  /// %로 표시되는 스탯인지
  bool get isPercent => const {
        Stat.hp: false,
        Stat.damage: false,
        Stat.accuracy: false,
        Stat.defense: false,
        Stat.critChance: true,
        Stat.critDamage: true,
        Stat.penetration: true,
        Stat.dodge: true,
        Stat.attackSpeed: true,
        Stat.lifesteal: true,
        Stat.goldFind: true,
      }[this]!;

  bool get isMain =>
      this == Stat.hp ||
      this == Stat.damage ||
      this == Stat.accuracy ||
      this == Stat.defense;

  /// 저장값 → 표시 문자열 (critDamage만 분수→%)
  String display(double v) {
    if (!isPercent) return '+${v.round()}';
    if (this == Stat.critDamage) return '+${(v * 100).round()}%';
    return '+${v.round()}%';
  }
}

/// 등급
enum Rarity { common, uncommon, rare, epic, legendary }

extension RarityInfo on Rarity {
  String get label => const {
        Rarity.common: '일반',
        Rarity.uncommon: '고급',
        Rarity.rare: '희귀',
        Rarity.epic: '영웅',
        Rarity.legendary: '전설',
      }[this]!;

  Color get color => const {
        Rarity.common: Color(0xFF9E9E9E),
        Rarity.uncommon: Color(0xFF4CAF50),
        Rarity.rare: Color(0xFF2196F3),
        Rarity.epic: Color(0xFF9C27B0),
        Rarity.legendary: Color(0xFFFF9800),
      }[this]!;

  double get mult => const {
        Rarity.common: 1.0,
        Rarity.uncommon: 1.4,
        Rarity.rare: 1.9,
        Rarity.epic: 2.6,
        Rarity.legendary: 3.6,
      }[this]!;

  /// 강화 상한
  int get enhanceMax => const {
        Rarity.common: 5,
        Rarity.uncommon: 8,
        Rarity.rare: 11,
        Rarity.epic: 13,
        Rarity.legendary: 15,
      }[this]!;

  /// 드랍 시 부옵션 슬롯 수 (영웅은 강화로 +1)
  int get subSlots => const {
        Rarity.common: 0,
        Rarity.uncommon: 1,
        Rarity.rare: 2,
        Rarity.epic: 2,
        Rarity.legendary: 3,
      }[this]!;

  Rarity? get next {
    final i = index;
    return i < Rarity.values.length - 1 ? Rarity.values[i + 1] : null;
  }

  /// 진화 시 필요한 진화석
  int get evolveStones => const {
        Rarity.common: 2, // → 고급
        Rarity.uncommon: 4, // → 희귀
        Rarity.rare: 8, // → 영웅
        Rarity.epic: 16, // → 전설
        Rarity.legendary: 0,
      }[this]!;
}

/// 부위별 메인스탯(flat 4종 중)
const slotMainStats = {
  Slot.weapon: [Stat.damage, Stat.accuracy],
  Slot.offhand: [Stat.defense, Stat.hp],
  Slot.helmet: [Stat.hp, Stat.defense],
  Slot.armor: [Stat.hp, Stat.defense],
  Slot.gloves: [Stat.damage, Stat.accuracy],
  Slot.boots: [Stat.hp, Stat.accuracy],
  Slot.amulet: [Stat.accuracy, Stat.defense],
  Slot.ring: [Stat.damage, Stat.hp],
  Slot.pet: [Stat.damage, Stat.hp],
};

const _mainBase = {
  Stat.hp: 12.0,
  Stat.damage: 2.2,
  Stat.accuracy: 3.0,
  Stat.defense: 2.0,
};

/// 부옵션 풀(7종)
const subAffixPool = [
  Stat.critChance,
  Stat.critDamage,
  Stat.penetration,
  Stat.dodge,
  Stat.attackSpeed,
  Stat.lifesteal,
  Stat.goldFind,
];

/// 부옵션 기준값 범위 (일반 기준, 적용 시 *rarityMult)
const _subRange = {
  Stat.critChance: [1.5, 3.0],
  Stat.critDamage: [0.06, 0.12],
  Stat.penetration: [3.0, 8.0],
  Stat.dodge: [2.0, 4.0],
  Stat.attackSpeed: [2.0, 5.0],
  Stat.lifesteal: [2.0, 5.0],
  Stat.goldFind: [5.0, 12.0],
};

/// 부위별 부옵션 출현 가중
const _subWeight = {
  // 공격계
  Slot.weapon: {
    Stat.critChance: 3,
    Stat.critDamage: 3,
    Stat.attackSpeed: 3,
    Stat.lifesteal: 2,
    Stat.penetration: 2,
    Stat.dodge: 1,
    Stat.goldFind: 1,
  },
  Slot.gloves: {
    Stat.critChance: 3,
    Stat.critDamage: 2,
    Stat.attackSpeed: 3,
    Stat.penetration: 2,
    Stat.lifesteal: 2,
    Stat.dodge: 1,
    Stat.goldFind: 1,
  },
  Slot.ring: {
    Stat.critChance: 3,
    Stat.critDamage: 3,
    Stat.lifesteal: 3,
    Stat.attackSpeed: 2,
    Stat.penetration: 2,
    Stat.dodge: 1,
    Stat.goldFind: 1,
  },
  Slot.pet: {
    Stat.critDamage: 3,
    Stat.attackSpeed: 2,
    Stat.critChance: 2,
    Stat.lifesteal: 2,
    Stat.penetration: 2,
    Stat.dodge: 2,
    Stat.goldFind: 2,
  },
  // 방어계
  Slot.helmet: {
    Stat.dodge: 3,
    Stat.lifesteal: 3,
    Stat.critChance: 1,
    Stat.critDamage: 1,
    Stat.attackSpeed: 1,
    Stat.penetration: 1,
    Stat.goldFind: 1,
  },
  Slot.armor: {
    Stat.dodge: 3,
    Stat.lifesteal: 3,
    Stat.critChance: 1,
    Stat.critDamage: 1,
    Stat.attackSpeed: 1,
    Stat.penetration: 1,
    Stat.goldFind: 1,
  },
  Slot.offhand: {
    Stat.dodge: 3,
    Stat.lifesteal: 3,
    Stat.penetration: 1,
    Stat.critChance: 1,
    Stat.critDamage: 1,
    Stat.attackSpeed: 1,
    Stat.goldFind: 1,
  },
  Slot.boots: {
    Stat.dodge: 3,
    Stat.lifesteal: 2,
    Stat.attackSpeed: 2,
    Stat.critChance: 1,
    Stat.critDamage: 1,
    Stat.penetration: 1,
    Stat.goldFind: 1,
  },
  // 목걸이: 균등 + goldFind↑
  Slot.amulet: {
    Stat.goldFind: 4,
    Stat.critChance: 2,
    Stat.critDamage: 2,
    Stat.penetration: 2,
    Stat.dodge: 2,
    Stat.attackSpeed: 2,
    Stat.lifesteal: 2,
  },
};

/// 강화 배수 (메인스탯에만 적용)
double enhanceMult(int level) {
  if (level <= 0) return 1.0;
  double m = 1.0;
  for (int i = 1; i <= level; i++) {
    if (i <= 10) {
      m += 0.08;
    } else if (i <= 13) {
      m += 0.12;
    } else if (i == 14) {
      m += 0.15;
    } else {
      m += 0.30; // +15
    }
  }
  return m;
}

/// 강화 비용(L→L+1), 골드
int enhanceCost(Equipment e, int fromLevel) {
  final weaponMult = e.slot == Slot.weapon ? 1.25 : 1.0;
  return (50 * pow(1.55, fromLevel) * e.rarity.mult * weaponMult).round();
}

/// 강화 성공률(기본, pity 별도)
double enhanceBaseRate(int toLevel) {
  if (toLevel <= 9) return 1.0;
  return const {10: 0.80, 11: 0.65, 12: 0.50, 13: 0.35, 14: 0.25, 15: 0.15}[
          toLevel] ??
      0.15;
}

/// 젬 확정권 비용
int enhanceGemCost(int toLevel) {
  if (toLevel <= 9) return 0;
  if (toLevel <= 12) return 30;
  if (toLevel == 13) return 60;
  if (toLevel == 14) return 100;
  return 150;
}

const _nameBank = {
  Slot.weapon: ['낡은 검', '강철 검', '용살자 검', '서리칼날', '폭풍의 대검'],
  Slot.offhand: ['나무 방패', '개구리 부적', '강철 방패', '수호의 룬', '용비늘 방패'],
  Slot.helmet: ['가죽 모자', '강철 투구', '기사 투구', '용기의 관', '왕관'],
  Slot.armor: ['천 갑옷', '사슬 갑옷', '판금 갑옷', '용비늘 갑옷', '불멸의 흉갑'],
  Slot.gloves: ['천 장갑', '가죽 장갑', '강철 건틀릿', '맹공의 장갑', '거인의 손'],
  Slot.boots: ['헝겊 신발', '여행자 부츠', '강철 정강이', '바람의 신발', '천보'],
  Slot.amulet: ['자연의 목걸이', '번개 부적', '수호의 목걸이', '현자의 메달', '신성의 목걸이'],
  Slot.ring: ['구리 반지', '은 반지', '룬 반지', '흡혈의 반지', '제왕의 반지'],
  Slot.pet: ['아기 슬라임', '여우', '독수리', '서리늑대', '어린 드래곤'],
};

class Equipment {
  final Slot slot;
  Rarity rarity;
  int itemLevel;
  String name;
  final Map<Stat, double> main; // 메인스탯(강화 전 base)
  final Map<Stat, double> subs; // 부옵션
  int enhanceLevel;
  int enhanceFailStreak; // 강화 pity(아이템·현재단계별, 성공 시 0)

  Equipment({
    required this.slot,
    required this.rarity,
    required this.itemLevel,
    required this.name,
    required this.main,
    required this.subs,
    this.enhanceLevel = 0,
    this.enhanceFailStreak = 0,
  });

  /// 강화 반영된 메인스탯 실효값
  double effMain(Stat s) => (main[s] ?? 0) * enhanceMult(enhanceLevel);

  /// 부옵션 실효값(강화 미반영)
  double sub(Stat s) => subs[s] ?? 0;

  static double _statWeight(Stat s, double v) {
    switch (s) {
      case Stat.hp:
        return v / 5;
      case Stat.damage:
        return v * 2;
      case Stat.accuracy:
        return v;
      case Stat.defense:
        return v;
      case Stat.critChance:
        return v * 2;
      case Stat.critDamage:
        return v * 100;
      case Stat.penetration:
        return v * 2;
      case Stat.dodge:
        return v * 2;
      case Stat.attackSpeed:
        return v * 4;
      case Stat.lifesteal:
        return v * 3;
      case Stat.goldFind:
        return 0;
    }
  }

  int _power({required bool enhanced}) {
    double p = 0;
    final mult = enhanced ? enhanceMult(enhanceLevel) : 1.0;
    main.forEach((s, v) => p += _statWeight(s, v * mult));
    subs.forEach((s, v) => p += _statWeight(s, v));
    return p.round();
  }

  int get power => _power(enhanced: true);
  int get basePower => _power(enhanced: false);

  /// 판매가 — 강화 미반영(차익 차단)
  int get sellPrice => (basePower * 4 + itemLevel * 10).round();

  int get maxEnhance => rarity.enhanceMax;

  Equipment copy() => Equipment(
        slot: slot,
        rarity: rarity,
        itemLevel: itemLevel,
        name: name,
        main: Map.of(main),
        subs: Map.of(subs),
        enhanceLevel: enhanceLevel,
        enhanceFailStreak: enhanceFailStreak,
      );

  // ---- 직렬화 ----
  Map<String, dynamic> toJson() => {
        's': slot.index,
        'r': rarity.index,
        'l': itemLevel,
        'n': name,
        'e': enhanceLevel,
        'f': enhanceFailStreak,
        'm': main.map((k, v) => MapEntry(k.index.toString(), v)),
        'b': subs.map((k, v) => MapEntry(k.index.toString(), v)),
      };

  static int _idx(dynamic v, int maxLen) {
    final i = (v is num) ? v.toInt() : 0;
    return i.clamp(0, maxLen - 1);
  }

  static Map<Stat, double> _statMap(dynamic m) {
    final map = <Stat, double>{};
    if (m is Map) {
      m.forEach((k, v) {
        final i = int.tryParse(k.toString());
        if (i != null && i >= 0 && i < Stat.values.length && v is num) {
          map[Stat.values[i]] = v.toDouble();
        }
      });
    }
    return map;
  }

  static Equipment fromJson(Map<String, dynamic> j) => Equipment(
        slot: Slot.values[_idx(j['s'], Slot.values.length)],
        rarity: Rarity.values[_idx(j['r'], Rarity.values.length)],
        itemLevel: (j['l'] as num?)?.toInt() ?? 1,
        name: (j['n'] as String?) ?? '장비',
        enhanceLevel: (j['e'] as num?)?.toInt() ?? 0,
        enhanceFailStreak: (j['f'] as num?)?.toInt() ?? 0,
        main: _statMap(j['m']),
        subs: _statMap(j['b']),
      );

  // ---- 생성 ----
  static Equipment generate(int itemLevel,
      {Slot? forceSlot, Rarity? forceRarity}) {
    final slot = forceSlot ?? Slot.values[_rng.nextInt(Slot.values.length)];
    final rarity = forceRarity ?? _rollRarity();
    final iLv = max(1, itemLevel);
    final names = _nameBank[slot]!;
    final nameIdx =
        (rarity.index + _rng.nextInt(2)).clamp(0, names.length - 1);

    // 메인스탯
    final main = <Stat, double>{};
    for (final st in slotMainStats[slot]!) {
      final base = _mainBase[st]!;
      final v = (base * iLv * rarity.mult * (0.8 + _rng.nextDouble() * 0.5));
      main[st] = max(1, v.round()).toDouble();
    }
    // 부옵션
    final subs = _rollSubs(slot, rarity);

    return Equipment(
      slot: slot,
      rarity: rarity,
      itemLevel: iLv,
      name: names[nameIdx],
      main: main,
      subs: subs,
    );
  }

  static Map<Stat, double> _rollSubs(Slot slot, Rarity rarity,
      {int? count}) {
    final n = count ?? rarity.subSlots;
    final subs = <Stat, double>{};
    if (n <= 0) return subs;
    final weights = Map<Stat, int>.from(_subWeight[slot]!);
    for (int i = 0; i < n && weights.isNotEmpty; i++) {
      final picked = _weightedPick(weights);
      weights.remove(picked); // 중복 금지
      subs[picked] = _rollSubValue(picked, rarity);
    }
    return subs;
  }

  static double _rollSubValue(Stat s, Rarity rarity) {
    final r = _subRange[s]!;
    final raw = (r[0] + _rng.nextDouble() * (r[1] - r[0])) * rarity.mult;
    if (s == Stat.critDamage) {
      return (raw * 100).round() / 100; // 소수 2자리
    }
    return max(1, raw.round()).toDouble();
  }

  static Stat _weightedPick(Map<Stat, int> weights) {
    final total = weights.values.fold(0, (a, b) => a + b);
    int r = _rng.nextInt(total);
    for (final e in weights.entries) {
      r -= e.value;
      if (r < 0) return e.key;
    }
    return weights.keys.first;
  }

  static Rarity _rollRarity() {
    final r = _rng.nextDouble();
    if (r < 0.50) return Rarity.common;
    if (r < 0.78) return Rarity.uncommon;
    if (r < 0.93) return Rarity.rare;
    if (r < 0.99) return Rarity.epic;
    return Rarity.legendary;
  }

  /// 부옵션 재추첨(리롤권)
  void rerollSubs() {
    final n = subs.length;
    subs.clear();
    subs.addAll(_rollSubs(slot, rarity, count: n));
  }
}

class Monster {
  final String name;
  final String emoji;
  double hp;
  final double maxHp;
  final double damage;
  final double defense;
  final int goldReward;
  final int xpReward;
  final bool isBoss;

  Monster({
    required this.name,
    required this.emoji,
    required this.maxHp,
    required this.damage,
    required this.defense,
    required this.goldReward,
    required this.xpReward,
    this.isBoss = false,
  }) : hp = maxHp;

  static const _bank = [
    ['슬라임', '🟢'],
    ['해골', '💀'],
    ['박쥐', '🦇'],
    ['거미', '🕷️'],
    ['고블린', '👺'],
    ['늑대', '🐺'],
    ['오크', '👹'],
    ['유령', '👻'],
  ];
  static const _bossBank = [
    ['해골왕', '☠️'],
    ['독거미 여왕', '🕸️'],
    ['오크 군주', '👹'],
    ['고대 골렘', '🗿'],
    ['붉은 드래곤', '🐲'],
  ];

  static Monster spawn(int progress, {bool boss = false}) {
    final hpScale = 1 + progress * 0.33;
    final dmgScale = 1 + progress * 0.44;
    if (boss) {
      final b = _bossBank[progress % _bossBank.length];
      return Monster(
        name: b[0],
        emoji: b[1],
        maxHp: (60 * hpScale * 3.2).roundToDouble(),
        damage: (6 * dmgScale * 1.6),
        defense: (4 * hpScale * 3.2),
        goldReward: (40 * hpScale * 4).round(),
        xpReward: (30 * hpScale * 3).round(),
        isBoss: true,
      );
    }
    final m = _bank[_rng.nextInt(_bank.length)];
    return Monster(
      name: m[0],
      emoji: m[1],
      maxHp: (28 * hpScale).roundToDouble(),
      damage: (5 * dmgScale),
      defense: (2 * hpScale),
      goldReward: (10 * hpScale).round(),
      xpReward: (8 * hpScale).round(),
    );
  }
}

class FloatingText {
  final String text;
  final Color color;
  final Offset start;
  double life;
  final double maxLife;
  final double size;
  FloatingText(this.text, this.color, this.start,
      {this.maxLife = 0.9, this.size = 22})
      : life = maxLife;
}
