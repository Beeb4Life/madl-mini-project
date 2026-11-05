import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Minimalist Nothing OS-inspired geometric PetSync Logo.
/// Features a stylized pet paw, concentric digital sync orbit, and iconic red dot.
class PetSyncLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isPro;

  const PetSyncLogo({
    super.key,
    this.size = 28,
    this.showText = false,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PetSyncLogoPainter(),
      ),
    );

    if (!showText) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Row(
          children: [
            const Text(
              'PETSYNC',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
                color: Colors.white,
              ),
            ),
            if (isPro) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PetSyncLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Background squircle / circle
    final bgPaint = Paint()
      ..color = const Color(0xFF16161C)
      ..style = PaintingStyle.fill;
    final bgBorderPaint = Paint()
      ..color = const Color(0xFF2C2C36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, w * 0.04);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.28),
    );
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, bgBorderPaint);

    // Sync Orbit ring (dashed Nothing style)
    final ringPaint = Paint()
      ..color = const Color(0xFF7E7E92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, w * 0.045)
      ..strokeCap = StrokeCap.round;

    final ringRadius = radius * 0.68;
    // Draw segmented arc 1
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -0.4,
      3.2,
      false,
      ringPaint,
    );
    // Draw segmented arc 2
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      3.6,
      1.8,
      false,
      ringPaint,
    );

    // Paw main pad (rounded bean / soft triangle)
    final pawPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final palmCenter = Offset(w / 2, h * 0.58);
    final palmRect = Rect.fromCenter(
      center: palmCenter,
      width: w * 0.32,
      height: h * 0.24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(palmRect, Radius.circular(w * 0.10)),
      pawPaint,
    );

    // 4 Paw Toes
    final toeWidth = w * 0.09;
    final toeHeight = h * 0.13;
    final toes = [
      Offset(w * 0.33, h * 0.44), // far left
      Offset(w * 0.44, h * 0.35), // mid left
      Offset(w * 0.56, h * 0.35), // mid right
      Offset(w * 0.67, h * 0.44), // far right
    ];

    for (final toe in toes) {
      canvas.drawOval(
        Rect.fromCenter(center: toe, width: toeWidth, height: toeHeight),
        pawPaint,
      );
    }

    // Iconic Nothing Red Dot
    final redDotCenter = Offset(w * 0.76, h * 0.24);
    final redPaint = Paint()
      ..color = AppColors.accentRed
      ..style = PaintingStyle.fill;
    canvas.drawCircle(redDotCenter, max(2.5, w * 0.09), redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
