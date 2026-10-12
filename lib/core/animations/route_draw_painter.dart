import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RouteDrawPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double busPosition; // 0.0 to 1.0

  RouteDrawPainter({
    required this.progress,
    required this.busPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final startPoint = Offset(size.width * 0.1, size.height * 0.6);
    final controlPoint1 = Offset(size.width * 0.35, size.height * 0.2);
    final controlPoint2 = Offset(size.width * 0.65, size.height * 0.85);
    final endPoint = Offset(size.width * 0.9, size.height * 0.4);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    // Background faint path
    final bgPaint = Paint()
      ..color = AppColors.lightBlue
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, bgPaint);

    // Animated blue drawn path
    if (progress > 0) {
      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final totalLength = metric.length;
        final extractLength = totalLength * progress.clamp(0.0, 1.0);
        final extractedPath = metric.extractPath(0.0, extractLength);

        final activePaint = Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.secondaryBlue, AppColors.primaryBlue],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(extractedPath, activePaint);

        // Start & End stop dots
        final dotPaint = Paint()..color = AppColors.primaryBlue;
        canvas.drawCircle(startPoint, 5, dotPaint);

        if (progress >= 0.98) {
          canvas.drawCircle(endPoint, 6, dotPaint);
          final innerDot = Paint()..color = Colors.white;
          canvas.drawCircle(endPoint, 3, innerDot);
        }

        // Draw animated bus icon marker along curve
        if (busPosition > 0.0) {
          final busMetricLength = totalLength * busPosition.clamp(0.0, 1.0);
          final tangent = metric.getTangentForOffset(busMetricLength);
          if (tangent != null) {
            final busCenter = tangent.position;

            // Outer glow
            final glowPaint = Paint()
              ..color = AppColors.primaryBlue.withOpacity(0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
            canvas.drawCircle(busCenter, 14, glowPaint);

            // Inner circle
            final pinPaint = Paint()..color = AppColors.primaryBlue;
            canvas.drawCircle(busCenter, 10, pinPaint);

            final pinCenter = Paint()..color = Colors.white;
            canvas.drawCircle(busCenter, 4, pinCenter);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant RouteDrawPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.busPosition != busPosition;
  }
}
