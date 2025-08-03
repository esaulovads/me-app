import 'package:flutter/material.dart';

/// Оптимизированный виджет прогресс-бара сна
class SleepProgressBar extends StatelessWidget {
  final double actualSleepHours; // Фактическое количество часов сна
  final double recommendedSleepHours; // Рекомендуемое количество часов сна
  final VoidCallback? onTap; // Колбэк для нажатия на виджет

  const SleepProgressBar({
    Key? key,
    required this.actualSleepHours,
    required this.recommendedSleepHours,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Вычисляем процент выполнения
    final percentage = recommendedSleepHours > 0
        ? (actualSleepHours / recommendedSleepHours).clamp(0.0, 1.0)
        : 0.0;

    // Определяем цвет прогресс-бара на основе процента выполнения
    Color progressColor;
    if (percentage >= 0.8 && percentage <= 1.2) {
      // 80-120% - зеленый (оптимально)
      progressColor = Colors.green;
    } else if (percentage >= 0.6 && percentage < 1.4) {
      // 60-79% или 121-140% - оранжевый (приемлемо)
      progressColor = Colors.orange;
    } else {
      // < 60% или > 140% - красный (плохо)
      progressColor = Colors.red;
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Иконка сна (полумесяц)
              const Icon(
                Icons.bedtime,
                color: Colors.indigo,
                size: 24,
              ),
              const SizedBox(width: 16),
              
              // Улучшенный прогресс-бар с автоматическим заполнением краев
              Expanded(
                child: _buildEnhancedProgressBar(percentage, progressColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Форматирует количество часов в читаемый вид
  String _formatHours(double hours) {
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();

    if (minutes == 0) {
      return '${wholeHours} ч';
    } else {
      return '${wholeHours} ч ${minutes} мин';
    }
  }

  // Строит улучшенный прогресс-бар с автоматическим заполнением краев
  Widget _buildEnhancedProgressBar(double percentage, Color progressColor) {
    const double barHeight = 12.0;
    const double borderRadius = 6.0;
    const double edgeWidth = 8.0; // Ширина крайних областей
    
    // Определяем цвет левой области (всегда заполнена)
    Color leftEdgeColor = percentage > 0 ? progressColor : Colors.red;
    
    // Определяем цвет правой области (заполняется при 100%)
    Color rightEdgeColor = percentage >= 1.0 ? Colors.green : Colors.grey[200]!;
    
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Row(
          children: [
            // Левая область - всегда заполнена
            Container(
              width: edgeWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: leftEdgeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(borderRadius - 1),
                  bottomLeft: Radius.circular(borderRadius - 1),
                ),
              ),
            ),
            
            // Средняя область - динамически заполняется
            Expanded(
              child: Container(
                height: barHeight,
                color: Colors.grey[200],
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    color: progressColor,
                  ),
                ),
              ),
            ),
            
            // Правая область - заполняется при 100%
            Container(
              width: edgeWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: rightEdgeColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(borderRadius - 1),
                  bottomRight: Radius.circular(borderRadius - 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


} 