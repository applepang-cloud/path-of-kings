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

/// 스탯 종류
enum Stat { hp, damage, accuracy, defense, lifesteal }

extension StatInfo on Stat {
  String get label => const {
        Stat.hp: '체력',
        Stat.damage: '피해',
        Stat.accuracy: '명중',
        Stat.defense: '방어력',
        Stat.lifesteal: '흡혈',
      }[this]!;
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
}

/// 부위별 이름 후보 (등급 무관 베이스)
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

/// 부위별로 어떤 스탯을 주는지
const _slotStats = {
  Slot.weapon: [Stat.damage, Stat.accuracy],
  Slot.offhand: [Stat.defense, Stat.lifesteal],
  Slot.helmet: [Stat.hp, Stat.defense],
  Slot.armor: [Stat.hp, Stat.defense],
  Slot.gloves: [Stat.damage, Stat.accuracy],
  Slot.boots: [Stat.hp, Stat.accuracy],
  Slot.amulet: [Stat.accuracy, Stat.defense, Stat.lifesteal],
  Slot.ring: [Stat.damage, Stat.lifesteal],
  Slot.pet: [Stat.damage, Stat.hp],
};

class Equipment {
  final Slot slot;
  final Rarity rarity;
  final int level;
  final String name;
  final Map<Stat, int> stats;

  Equipment({
    required this.slot,
    required this.rarity,
    required this.level,
    required this.name,
    required this.stats,
  });

  /// 전투력 환산
  int get power {
    int p = 0;
    stats.forEach((s, v) {
      p += switch (s) {
        Stat.hp => (v / 5).round(),
        Stat.damage => v * 2,
        Stat.accuracy => v,
        Stat.defense => v,
        Stat.lifesteal => v * 3,
      };
    });
    return p;
  }

  /// 판매가
  int get sellPrice => (power * 4 + level * 10).round();

  static Equipment random(int powerLevel, {Slot? forceSlot, Rarity? forceRarity}) {
    final slot = forceSlot ?? Slot.values[_rng.nextInt(Slot.values.length)];
    final rarity = forceRarity ?? _rollRarity();
    final level = max(1, powerLevel + _rng.nextInt(3) - 1);
    final names = _nameBank[slot]!;
    // 등급이 높을수록 뒤쪽(강력한) 이름
    final nameIdx = min(names.length - 1,
        (rarity.index + _rng.nextInt(2)).clamp(0, names.length - 1));
    final name = names[nameIdx];

    final statKeys = _slotStats[slot]!;
    final stats = <Stat, int>{};
    for (final st in statKeys) {
      final base = switch (st) {
        Stat.hp => 12.0,
        Stat.damage => 2.2,
        Stat.accuracy => 3.0,
        Stat.defense => 2.0,
        Stat.lifesteal => 1.0,
      };
      final v = (base * level * rarity.mult * (0.8 + _rng.nextDouble() * 0.5))
          .round();
      stats[st] = max(1, v);
    }
    return Equipment(
        slot: slot, rarity: rarity, level: level, name: name, stats: stats);
  }

  static Rarity _rollRarity() {
    final r = _rng.nextDouble();
    if (r < 0.50) return Rarity.common;
    if (r < 0.78) return Rarity.uncommon;
    if (r < 0.93) return Rarity.rare;
    if (r < 0.99) return Rarity.epic;
    return Rarity.legendary;
  }
}

class Monster {
  final String name;
  final String emoji;
  double hp;
  final double maxHp;
  final double damage;
  final int goldReward;
  final int xpReward;
  final bool isBoss;

  Monster({
    required this.name,
    required this.emoji,
    required this.maxHp,
    required this.damage,
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
    // 체력은 완만하게, 공격력은 더 가파르게 → 장비로 못 따라가면 맞아 죽음
    final hpScale = 1 + progress * 0.30;
    final dmgScale = 1 + progress * 0.42;
    if (boss) {
      final b = _bossBank[progress % _bossBank.length];
      return Monster(
        name: b[0],
        emoji: b[1],
        maxHp: (60 * hpScale * 3.2).roundToDouble(),
        damage: (6 * dmgScale * 1.6),
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
