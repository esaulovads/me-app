import 'package:flutter/material.dart';

class NutritionProgressBar extends StatelessWidget {
  final double consumedCalories;
  final double targetCalories;
  final VoidCallback onTap;

  const NutritionProgressBar({
    Key? key,
    required this.consumedCalories,
    required this.targetCalories,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Вычисляем процент от дневной нормы
    final double percentage = targetCalories > 0 
        ? (consumedCalories / targetCalories).clamp(0.0, 1.0) 
        : 0.0;
    
    // Определяем цвет прогресс-бара на основе процента
    Color progressColor;
    if (percentage >= 0.8) {
      progressColor = Colors.green; // Зелёный - более 80%
    } else if (percentage >= 0.4) {
      progressColor = Colors.orange; // Жёлтый - от 40% до 80%
    } else {
      progressColor = Colors.red; // Красный - менее 40%
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
                const Text(
                  'Питание',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Информация о калориях
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${consumedCalories.toInt()} / ${targetCalories.toInt()} ккал',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
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
} 