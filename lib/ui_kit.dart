import 'package:flutter/material.dart';
import 'models.dart';

// 공통 색상
const kPanelBg = Color(0xFF2a1d12);
const kPanelBg2 = Color(0xFF3a2a1a);
const kBorder = Color(0xFF7a5a3a);
const kGold = Color(0xFFFFD54F);
const kGreen = Color(0xFF69F0AE);
const kRed = Color(0xFFFF5252);

String fmtNum(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toString();
}

String fmtDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '$h시간 $m분';
  return '$m분';
}

BoxDecoration panelDeco({Color? border, double width = 2, Color? bg}) =>
    BoxDecoration(
      color: bg ?? kPanelBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border ?? kBorder, width: width),
    );

/// 재화 칩
class CurrencyChip extends StatelessWidget {
  final String emoji;
  final int value;
  final Color color;
  const CurrencyChip(
      {super.key,
      required this.emoji,
      required this.value,
      this.color = kGold});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kPanelBg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text(fmtNum(value),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

/// 섹션 제목
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(children: [
        Container(width: 4, height: 16, color: kGold),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ]),
    );
  }
}

/// 액션 버튼
class GameButton extends StatelessWidget {
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  const GameButton(
      {super.key,
      required this.label,
      this.sub,
      this.onTap,
      this.color = const Color(0xFF6abf3a),
      this.icon});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
              if (sub != null)
                Text(sub!,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 스탯 한 줄 (증감 화살표 옵션)
class StatRow extends StatelessWidget {
  final Stat stat;
  final double value;
  final double? compareTo; // 비교 대상(증감 표시)
  const StatRow(
      {super.key, required this.stat, required this.value, this.compareTo});
  @override
  Widget build(BuildContext context) {
    final diff = compareTo == null ? 0 : value - compareTo!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(stat.label,
              style: TextStyle(
                  color: stat.isMain ? Colors.white70 : const Color(0xFFB39DDB),
                  fontSize: 12.5)),
          Row(children: [
            Text(stat.display(value),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5)),
            if (diff != 0) ...[
              const SizedBox(width: 4),
              Icon(diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: diff > 0 ? kGreen : kRed, size: 13),
            ],
          ]),
        ],
      ),
    );
  }
}

/// 장비 상세 카드 (장착비교 옵션)
class EquipmentCardView extends StatelessWidget {
  final Equipment item;
  final Equipment? compareTo; // 현재 장착품(증감 비교)
  final bool showEnhance;
  const EquipmentCardView(
      {super.key, required this.item, this.compareTo, this.showEnhance = true});

  @override
  Widget build(BuildContext context) {
    final c = item.rarity.color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.withValues(alpha: 0.9), c.withValues(alpha: 0.45)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(item.slot.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.rarity.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (showEnhance && item.enhanceLevel > 0) ...[
                    const SizedBox(width: 4),
                    Text('+${item.enhanceLevel}',
                        style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(item.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('${item.slot.label} · iLv ${item.itemLevel} · ⚔️${item.power}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ]),
        const Divider(color: Colors.white38, height: 14),
        // 메인스탯
        for (final s in item.main.keys)
          StatRow(
            stat: s,
            value: item.effMain(s),
            compareTo: compareTo == null
                ? null
                : (compareTo!.main.containsKey(s)
                    ? compareTo!.effMain(s)
                    : 0),
          ),
        // 부옵션
        if (item.subs.isNotEmpty) ...[
          const SizedBox(height: 2),
          for (final s in item.subs.keys)
            StatRow(
              stat: s,
              value: item.sub(s),
              compareTo: compareTo?.sub(s),
            ),
        ],
      ]),
    );
  }
}

/// 인벤토리/장비 슬롯 작은 타일
class ItemTile extends StatelessWidget {
  final Equipment? item;
  final Slot? emptySlot;
  final VoidCallback? onTap;
  final bool selected;
  const ItemTile(
      {super.key, this.item, this.emptySlot, this.onTap, this.selected = false});
  @override
  Widget build(BuildContext context) {
    final rarity = item?.rarity;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Colors.white
                : (rarity?.color ?? const Color(0xFF6a4a2a)),
            width: selected ? 3 : 2.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text((item?.slot ?? emptySlot)?.emoji ?? '',
                style: TextStyle(
                    fontSize: 24,
                    color: item == null ? Colors.white24 : null)),
            if (item != null && item!.enhanceLevel > 0)
              Positioned(
                right: 2,
                top: 1,
                child: Text('+${item!.enhanceLevel}',
                    style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
              ),
            if (item != null)
              Positioned(
                left: 2,
                bottom: 1,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: rarity!.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${item!.itemLevel}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 메타 화면 공통 스캐폴드(제목 + 본문)
class MetaScaffold extends StatelessWidget {
  final String title;
  final String emoji;
  final Widget child;
  const MetaScaffold(
      {super.key,
      required this.title,
      required this.emoji,
      required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1c1410),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: kPanelBg2,
            child: Text('$emoji  $title',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// 간단 토스트
void gameToast(BuildContext context, String msg, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: color ?? kPanelBg2,
    duration: const Duration(milliseconds: 1400),
    behavior: SnackBarBehavior.floating,
  ));
}
