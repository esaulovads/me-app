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
          child: Row(
            children: [
              // Иконка питания
              const Icon(
                Icons.restaurant,
                color: Colors.orange,
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