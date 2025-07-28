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
    final percentageInt = (percentage * 100).round();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок блока
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.bedtime,
                        color: Colors.indigo,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Сон',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Информация о времени сна
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatHours(actualSleepHours)} / ${_formatHours(recommendedSleepHours)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$percentageInt%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Прогресс-бар
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
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


} 