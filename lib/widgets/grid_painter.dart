import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/avatar_model.dart';
import '../models/level_data.dart';

class GridPainter extends CustomPainter {
  final LevelData level;
  final GridPoint robotPos;
  final int robotDir; // 0: Yukarı, 1: Sağa, 2: Aşağı, 3: Sola
  final double animProgress;
  final GridPoint? targetPos;
  final int? targetDir;
  final bool isBumping;
  final bool hasKey;
  final List<GridPoint> remainingStars;
  final List<GridPoint> remainingKeys;
  final List<GridPoint> openedDoors;
  final AvatarModel avatar;
  final double time;

  GridPainter({
    required this.level,
    required this.robotPos,
    required this.robotDir,
    this.animProgress = 1.0,
    this.targetPos,
    this.targetDir,
    this.isBumping = false,
    required this.hasKey,
    required this.remainingStars,
    required this.remainingKeys,
    required this.openedDoors,
    required this.avatar,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cols = level.cols;
    final rows = level.rows;
    const pad = 16.0;

    final availW = size.width - pad * 2;
    final availH = size.height - pad * 2;

    final cellSize = math.min(availW / cols, availH / rows).clamp(35.0, 75.0);
    final offsetX = (size.width - cols * cellSize) / 2;
    final offsetY = (size.height - rows * cellSize) / 2;

    // 1. Zemin Izgarası
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = offsetX + c * cellSize;
        final y = offsetY + r * cellSize;
        final isEven = (r + c) % 2 == 0;

        final fillPaint = Paint()
          ..color = isEven ? const Color(0xFFE8F5E9) : const Color(0xFFC8E6C9)
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = const Color(0xFFA5D6A7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, y + 2, cellSize - 4, cellSize - 4),
          const Radius.circular(8),
        );

        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, borderPaint);
      }
    }

    // 2. Engeller (Taşlar)
    for (final obs in level.obstacles) {
      final x = offsetX + obs.x * cellSize;
      final y = offsetY + obs.y * cellSize;
      _drawObstacle(canvas, x, y, cellSize);
    }

    // 3. Kapılar
    for (final door in level.doors) {
      final x = offsetX + door.x * cellSize;
      final y = offsetY + door.y * cellSize;
      final isOpen = openedDoors.contains(door);
      _drawDoor(canvas, x, y, cellSize, isOpen);
    }

    // 4. Anahtarlar
    for (final key in remainingKeys) {
      final x = offsetX + key.x * cellSize;
      final y = offsetY + key.y * cellSize;
      _drawKey(canvas, x, y, cellSize);
    }

    // 5. Hedef Bayrağı
    final gx = offsetX + level.goal.x * cellSize;
    final gy = offsetY + level.goal.y * cellSize;
    _drawGoal(canvas, gx, gy, cellSize);

    // 6. Yıldızlar
    for (final star in remainingStars) {
      final sx = offsetX + star.x * cellSize;
      final sy = offsetY + star.y * cellSize;
      _drawStar(canvas, sx, sy, cellSize);
    }

    // 7. Karakter Avatarı
    _drawAvatar(canvas, offsetX, offsetY, cellSize);
  }

  void _drawObstacle(Canvas canvas, double x, double y, double cellSize) {
    final pad = cellSize * 0.15;
    final s = cellSize - pad * 2;
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2;

    final shadowPaint = Paint()..color = const Color(0x1F000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + s * 0.4), width: s * 0.9, height: s * 0.4),
      shadowPaint,
    );

    final stonePaint = Paint()..color = const Color(0xFF78909C);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + pad, y + pad, s, s),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, stonePaint);

    final mossPaint = Paint()..color = const Color(0xFF81C784);
    canvas.drawCircle(Offset(cx + s * 0.2, cy - s * 0.2), s * 0.12, mossPaint);
  }

  void _drawDoor(Canvas canvas, double x, double y, double cellSize, bool isOpen) {
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2;
    final s = cellSize * 0.7;

    if (isOpen) {
      final framePaint = Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: s, height: s), framePaint);
    } else {
      final doorPaint = Paint()..color = const Color(0xFFD32F2F);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: s, height: s),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, doorPaint);

      final lockPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(Offset(cx, cy - 2), 5, lockPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 3), width: 8, height: 6), lockPaint);
    }
  }

  void _drawKey(Canvas canvas, double x, double y, double cellSize) {
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2 + math.sin(time * 4) * 3;

    final keyPaint = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(Offset(cx - 5, cy), 6, keyPaint);
    final innerPaint = Paint()..color = const Color(0xFFE8F5E9);
    canvas.drawCircle(Offset(cx - 5, cy), 2.5, innerPaint);
    canvas.drawRect(Rect.fromLTWH(cx - 2, cy - 2, 10, 4), keyPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 4, cy + 2, 3, 3), keyPaint);
  }

  void _drawGoal(Canvas canvas, double x, double y, double cellSize) {
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2;
    final s = cellSize * 0.4;

    final basePaint = Paint()
      ..color = const Color(0xFFE1F5FE)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF0288D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset(cx, cy + 6), s * 0.8, basePaint);
    canvas.drawCircle(Offset(cx, cy + 6), s * 0.8, borderPaint);

    final polePaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawRect(Rect.fromLTWH(cx - 8, cy - 18, 2.5, 24), polePaint);

    final wave = math.sin(time * 5) * 2;
    final flagPath = Path()
      ..moveTo(cx - 6, cy - 18)
      ..lineTo(cx + 10 + wave, cy - 12)
      ..lineTo(cx - 6, cy - 6)
      ..close();
    final flagPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawPath(flagPath, flagPaint);
  }

  void _drawStar(Canvas canvas, double x, double y, double cellSize) {
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2 + math.sin(time * 3 + x) * 3;
    final r = cellSize * 0.22;

    final starPath = Path();
    const spikes = 5;
    const step = math.pi / spikes;
    var rot = (math.pi / 2) * 3;

    starPath.moveTo(cx, cy - r);
    for (int i = 0; i < spikes; i++) {
      starPath.lineTo(cx + math.cos(rot) * r, cy + math.sin(rot) * r);
      rot += step;
      starPath.lineTo(cx + math.cos(rot) * (r * 0.45), cy + math.sin(rot) * (r * 0.45));
      rot += step;
    }
    starPath.close();

    final starPaint = Paint()..color = const Color(0xFFFFC107);
    final borderPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(starPath, starPaint);
    canvas.drawPath(starPath, borderPaint);
  }

  void _drawAvatar(Canvas canvas, double offsetX, double offsetY, double cellSize) {
    final p = animProgress;

    double curX = robotPos.x.toDouble();
    double curY = robotPos.y.toDouble();

    if (targetPos != null) {
      curX = robotPos.x + (targetPos!.x - robotPos.x) * p;
      curY = robotPos.y + (targetPos!.y - robotPos.y) * p;
    }

    if (isBumping) {
      curX += (math.Random().nextDouble() - 0.5) * 0.12;
      curY += (math.Random().nextDouble() - 0.5) * 0.12;
    }

    final cx = offsetX + (curX + 0.5) * cellSize;
    final cy = offsetY + (curY + 0.5) * cellSize;
    final size = cellSize * 0.72;

    double startAngle = robotDir * (math.pi / 2);
    double endAngle = (targetDir ?? robotDir) * (math.pi / 2);
    if (endAngle - startAngle > math.pi) startAngle += math.pi * 2;
    if (startAngle - endAngle > math.pi) endAngle += math.pi * 2;
    final curAngle = startAngle + (endAngle - startAngle) * p;

    canvas.save();
    canvas.translate(cx, cy);

    final shadowPaint = Paint()..color = const Color(0x2E000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, size * 0.35), width: size * 0.8, height: size * 0.35),
      shadowPaint,
    );

    canvas.rotate(curAngle);

    // 1. Gövde
    final bodyPaint = Paint()..color = avatar.primaryColor;
    final borderPaint = Paint()
      ..color = avatar.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: size * 0.64, height: size * 0.64),
      const Radius.circular(10),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(bodyRRect, borderPaint);

    // 2. Yüz Ekranı
    final screenPaint = Paint()..color = const Color(0xFF263238);
    final screenRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: size * 0.48, height: size * 0.48),
      const Radius.circular(6),
    );
    canvas.drawRRect(screenRRect, screenPaint);

    // 3. Parlayan Gözler
    final eyePaint = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(Offset(-size * 0.11, -size * 0.06), size * 0.07, eyePaint);
    canvas.drawCircle(Offset(size * 0.11, -size * 0.06), size * 0.07, eyePaint);

    // 4. Burun / Yön Oku
    final nosePath = Path()
      ..moveTo(0, size * 0.14)
      ..lineTo(-size * 0.08, size * 0.03)
      ..lineTo(size * 0.08, size * 0.03)
      ..close();
    final nosePaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawPath(nosePath, nosePaint);

    // 5. Özel Aksesuarlar (8 Farklı Avatar Eklentisi)
    _drawAccessory(canvas, size);

    canvas.restore();

    if (hasKey) {
      final keyIconPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(Offset(cx + size * 0.35, cy - size * 0.35), 7, keyIconPaint);
    }
  }

  void _drawAccessory(Canvas canvas, double size) {
    switch (avatar.accessory) {
      case 'antenna':
        final antennaPaint = Paint()..color = const Color(0xFFFF7043);
        canvas.drawCircle(Offset(0, -size * 0.38), size * 0.06, antennaPaint);
        break;

      case 'helmet':
        final helmetPaint = Paint()
          ..color = const Color(0x7FE0E7FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(Offset(0, -size * 0.1), size * 0.38, helmetPaint);
        break;

      case 'climber':
        final bandPaint = Paint()..color = const Color(0xFF81C784);
        canvas.drawRect(Rect.fromCenter(center: Offset(0, -size * 0.2), width: size * 0.5, height: 4), bandPaint);
        break;

      case 'racer':
        final racerPaint = Paint()..color = const Color(0xFFFFEB3B);
        canvas.drawRect(Rect.fromCenter(center: Offset(0, -size * 0.32), width: size * 0.4, height: 4), racerPaint);
        break;

      case 'wizard':
        final hatPath = Path()
          ..moveTo(0, -size * 0.55)
          ..lineTo(-size * 0.25, -size * 0.3)
          ..lineTo(size * 0.25, -size * 0.3)
          ..close();
        final hatPaint = Paint()..color = const Color(0xFF7E57C2);
        canvas.drawPath(hatPath, hatPaint);
        break;

      case 'crown':
        final crownPath = Path()
          ..moveTo(-size * 0.22, -size * 0.3)
          ..lineTo(-size * 0.22, -size * 0.48)
          ..lineTo(-size * 0.1, -size * 0.38)
          ..lineTo(0, -size * 0.52)
          ..lineTo(size * 0.1, -size * 0.38)
          ..lineTo(size * 0.22, -size * 0.48)
          ..lineTo(size * 0.22, -size * 0.3)
          ..close();
        final crownPaint = Paint()..color = const Color(0xFFFFD700);
        canvas.drawPath(crownPath, crownPaint);
        break;

      case 'super':
        final capePath = Path()
          ..moveTo(-size * 0.2, -size * 0.1)
          ..lineTo(-size * 0.35, size * 0.3)
          ..lineTo(size * 0.35, size * 0.3)
          ..lineTo(size * 0.2, -size * 0.1)
          ..close();
        final capePaint = Paint()..color = const Color(0xFFD32F2F);
        canvas.drawPath(capePath, capePaint);
        break;

      case 'ninja':
        final bandPaint = Paint()..color = const Color(0xFFEF5350);
        canvas.drawRect(Rect.fromCenter(center: Offset(0, -size * 0.22), width: size * 0.55, height: 4), bandPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return true;
  }
}
