import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'game_state.dart';

/// 1인칭 전투 화면
class SceneView extends StatelessWidget {
  final GameState game;
  const SceneView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final shakeX = game.shake * 7 * (game.hitFlash > 0.5 ? 1 : -1);
      final shakeY = game.shake * 4;
      final m = game.monster;

      return ClipRect(
        child: Transform.translate(
          offset: Offset(shakeX, shakeY),
          child: Stack(
            children: [
              // 배경 (하늘/숲/길)
              Positioned.fill(child: CustomPaint(painter: _BgPainter())),

              // 전진 표시
              if (game.phase == Phase.walking)
                Positioned(
                  top: h * 0.42,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text('출발',
                          style: TextStyle(
                              color: const Color(0xFFFF7043),
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4)
                              ])),
                      const Text('🦶',
                          style: TextStyle(fontSize: 22)),
                    ],
                  ),
                ),

              // 몬스터
              if (m != null && game.phase != Phase.walking)
                Positioned(
                  left: w * 0.5 - (m.isBoss ? 80 : 55),
                  top: h * 0.26 + sin(game.slash * 6) * 4,
                  child: _MonsterWidget(monster: m, flash: game.hitFlash),
                ),

              // 베기 이펙트
              if (game.slash > 0.4)
                Positioned(
                  left: w * 0.42,
                  top: h * 0.30,
                  child: Opacity(
                    opacity: (game.slash).clamp(0, 1),
                    child: Transform.rotate(
                      angle: -0.6,
                      child: Container(
                        width: 120,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.transparent
                          ]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

              // 양손 (보조무기 / 무기)
              Positioned(
                left: -10,
                bottom: -20,
                child: _Hand(
                  emoji: game.equipped[Slot.offhand]?.slot.emoji ?? '🐸',
                  angle: 0.3,
                  flip: false,
                ),
              ),
              Positioned(
                right: -10,
                bottom: -30,
                child: Transform.rotate(
                  angle: -game.slash * 0.9,
                  alignment: Alignment.bottomRight,
                  child: _Hand(
                    emoji: game.equipped[Slot.weapon]?.slot.emoji ?? '🗡️',
                    angle: -0.5,
                    flip: true,
                  ),
                ),
              ),

              // 데미지/획득 플로팅 텍스트
              for (final f in game.floaters)
                Positioned(
                  left: f.start.dx * w,
                  top: f.start.dy * h - (1 - f.life / f.maxLife) * 50,
                  child: Opacity(
                    opacity: (f.life / f.maxLife).clamp(0, 1),
                    child: Text(f.text,
                        style: TextStyle(
                            color: f.color,
                            fontSize: f.size,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 3)
                            ])),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _MonsterWidget extends StatelessWidget {
  final Monster monster;
  final double flash;
  const _MonsterWidget({required this.monster, required this.flash});
  @override
  Widget build(BuildContext context) {
    final size = monster.isBoss ? 150.0 : 105.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 이름 / 보스 표시
        if (monster.isBoss)
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('👑 ${monster.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        // HP 바
        Container(
          width: size * 0.9,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF4a1010),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.black54, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              FractionallySizedBox(
                widthFactor: (monster.hp / monster.maxHp).clamp(0, 1),
                child: Container(color: const Color(0xFFE53935)),
              ),
              Center(
                child: Text(monster.hp.round().toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        // 몬스터 본체
        ColorFiltered(
          colorFilter: flash > 0.5
              ? const ColorFilter.mode(Colors.white, BlendMode.srcATop)
              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
          child: Text(monster.emoji, style: TextStyle(fontSize: size)),
        ),
      ],
    );
  }
}

class _Hand extends StatelessWidget {
  final String emoji;
  final double angle;
  final bool flip;
  const _Hand({required this.emoji, required this.angle, required this.flip});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 팔뚝
          Positioned(
            bottom: -20,
            left: flip ? null : 20,
            right: flip ? 20 : null,
            child: Transform.rotate(
              angle: flip ? 0.4 : -0.4,
              child: Container(
                width: 55,
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0A878), Color(0xFFB07848)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF6a4a2a), width: 3),
                ),
                // 소매 (가죽)
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6a4326),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 무기/아이템
          Positioned(
            top: 0,
            left: flip ? 30 : null,
            right: flip ? null : 30,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(angle)
                ..scaleByDouble(flip ? -1.0 : 1.0, 1.0, 1.0, 1.0),
              child: Text(emoji, style: const TextStyle(fontSize: 72)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 배경: 하늘 + 숲 + 잔디 + 원근 흙길
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.34;

    // 하늘
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7EC8E3), Color(0xFFBFE6F0)],
      ).createShader(Rect.fromLTWH(0, 0, w, horizon));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, horizon), sky);

    // 먼 숲 (어두운 초록 띠)
    final farForest = Paint()..color = const Color(0xFF2E5A34);
    final fp = Path()..moveTo(0, horizon);
    for (double x = 0; x <= w; x += 24) {
      fp.lineTo(x, horizon - 18 - (sin(x * 0.05) * 8).abs());
    }
    fp..lineTo(w, horizon)..close();
    canvas.drawPath(fp, farForest);

    // 잔디 (밝은 초록)
    final grass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6FBF4A), Color(0xFF4E9B33)],
      ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon));
    canvas.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), grass);

    // 원근 흙길 (사다리꼴)
    final road = Paint()..color = const Color(0xFF9B6B3A);
    final cx = w / 2;
    final roadPath = Path()
      ..moveTo(cx - 22, horizon)
      ..lineTo(cx + 22, horizon)
      ..lineTo(cx + w * 0.42, h)
      ..lineTo(cx - w * 0.42, h)
      ..close();
    canvas.drawPath(roadPath, road);

    // 길 테두리 (진한 흙)
    final edge = Paint()
      ..color = const Color(0xFF6E4A24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawPath(roadPath, edge);

    // 길 위 가로 줄무늬 (디딤돌 느낌)
    final stripe = Paint()..color = const Color(0xFF7E5226).withValues(alpha: 0.5);
    for (int i = 1; i <= 6; i++) {
      final t = i / 7;
      final y = horizon + (h - horizon) * t * t;
      final halfTop = 22 + (w * 0.42 - 22) * (t * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, y), width: halfTop * 2, height: 6),
        stripe,
      );
    }

    // 양옆 덤불
    final bush = Paint()..color = const Color(0xFF3E7A38);
    for (final bx in [w * 0.12, w * 0.88, w * 0.05, w * 0.95]) {
      canvas.drawCircle(Offset(bx, horizon + 30), 34, bush);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
