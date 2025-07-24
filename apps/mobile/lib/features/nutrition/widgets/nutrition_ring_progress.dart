import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Виджет кольцевого прогресса для отображения потребления нутриентов
/// Показывает основное кольцо (0-100%) и внутреннее кольцо при перерасходе (>100%)
class NutritionRingProgress extends StatelessWidget {
  final double actual; // Фактическое потребление
  final double target; // Целевое значение (норма)
  final double size; // Размер виджета
  final double strokeWidth; // Толщина кольца

  const NutritionRingProgress({
    Key? key,
    required this.actual,
    required this.target,
    this.size = 40.0,
    this.strokeWidth = 7.0, // На 22% тоньше (9 * 0.78 ≈ 7)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Если нет нормы, не показываем кольцо
    if (target <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey[300]!,
              width: strokeWidth,
            ),
          ),
          child: const Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    final percentage = actual / target;
    final mainProgress = percentage.clamp(0.0, 1.0); // Основное кольцо (0-100%)
    final overflowProgress = percentage > 1.0 ? (percentage - 1.0).clamp(0.0, 1.0) : 0.0; // Кольцо перерасхода
    
    // Цвет прогресса - если есть перерасход, все кольца зелёные
    final progressColor = percentage > 1.0 ? Colors.green : _getProgressColor(percentage);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Основное кольцо (фон)
          CustomPaint(
            size: Size(size, size),
            painter: _RingProgressPainter(
              progress: 1.0,
              color: Colors.grey[200]!,
              strokeWidth: strokeWidth,
            ),
          ),
          
          // Основное кольцо (прогресс)
          CustomPaint(
            size: Size(size, size),
            painter: _RingProgressPainter(
              progress: mainProgress,
              color: progressColor,
              strokeWidth: strokeWidth,
            ),
          ),
          
          // Кольцо перерасхода (внутреннее)
          if (overflowProgress > 0)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(strokeWidth + 2),
                child: CustomPaint(
                  painter: _RingProgressPainter(
                    progress: overflowProgress,
                    color: progressColor, // Тот же цвет, что и основное кольцо
                    strokeWidth: strokeWidth * 0.7, // Тоньше внутреннее кольцо
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Определяет цвет прогресса на основе процента от нормы
  Color _getProgressColor(double percentage) {
    if (percentage >= 0.8) {
      return Colors.green; // Зелёный - более 80%
    } else if (percentage >= 0.4) {
      return Colors.orange; // Оранжевый - от 40% до 80%
    } else {
      return Colors.red; // Красный - менее 40%
    }
  }
}

/// Кастомный painter для отрисовки кольца прогресса
class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Рисуем дугу от -90 градусов (верх) по часовой стрелке
    const startAngle = -math.pi / 2; // Начинаем сверху
    final sweepAngle = 2 * math.pi * progress; // Угол дуги

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _RingProgressPainter ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
} 