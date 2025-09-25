import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_model.dart';
import '../models/workout_schedule_model.dart';

/// Улучшенный виджет прогресс-бара физической активности с поддержкой норм тренировок
class ActivityProgressBar extends StatelessWidget {
  final List<Workout> todaysWorkouts; // Тренировки за сегодня
  final WorkoutSchedule? todaySchedule; // Расписание на сегодня
  final double? optimalDailyTrainingMinutes; // Оптимальное количество минут тренировок в день
  final VoidCallback? onTap; // Колбэк для нажатия на виджет

  const ActivityProgressBar({
    Key? key,
    required this.todaysWorkouts,
    this.todaySchedule,
    this.optimalDailyTrainingMinutes,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Определяем состояние прогресс-бара
    final progressState = _calculateProgressState();
    
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
              // Иконка активности (гантели)
              const Icon(
                Icons.fitness_center,
                color: Colors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 16),
              
              // Улучшенный прогресс-бар с правильной логикой
              Expanded(
                child: _buildTrainingProgressBar(progressState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Рассчитывает состояние прогресса тренировок
  _TrainingProgressState _calculateProgressState() {
    debugPrint('ActivityProgressBar: todaySchedule=${todaySchedule?.isActive}, workouts=${todaysWorkouts.length}, optimalMinutes=$optimalDailyTrainingMinutes');
    
    // Проверяем, есть ли расписание на сегодня
    if (todaySchedule == null || !todaySchedule!.isActive) {
      return _TrainingProgressState(
        type: _ProgressType.restDay,
        percentage: 0.0,
        color: Colors.grey,
        text: 'День отдыха',
      );
    }

    // Сегодня день тренировки - рассчитываем прогресс
    final totalTrainingMinutes = todaysWorkouts.fold<double>(
      0.0, 
      (sum, workout) => sum + (workout.duration ?? 0).toDouble(),
    );

    final targetMinutes = optimalDailyTrainingMinutes ?? 30.0; // Fallback значение
    final percentage = (totalTrainingMinutes / targetMinutes).clamp(0.0, 1.0);
    
    debugPrint('ActivityProgressBar: totalMinutes=$totalTrainingMinutes, targetMinutes=$targetMinutes, percentage=$percentage');
    
    // Определяем цвет на основе процента (как у прогресс-бара питания)
    Color progressColor;
    if (percentage >= 0.8) {
      progressColor = Colors.green; // 80%+ - отлично
    } else if (percentage >= 0.4) {
      progressColor = Colors.orange; // 40-79% - хорошо
    } else {
      progressColor = Colors.red; // < 40% - нужно больше
    }

    // Определяем тип состояния
    final type = totalTrainingMinutes > 0 ? _ProgressType.hasWorkout : _ProgressType.noWorkout;

    return _TrainingProgressState(
      type: type,
      percentage: percentage,
      color: progressColor,
      text: '${totalTrainingMinutes.round()} / ${targetMinutes.round()} мин',
    );
  }

  /// Строит прогресс-бар тренировок в зависимости от состояния
  Widget _buildTrainingProgressBar(_TrainingProgressState state) {
    switch (state.type) {
      case _ProgressType.restDay:
        return _buildRestDayBar(state);
      case _ProgressType.noWorkout:
        return _buildNoWorkoutBar(state);
      case _ProgressType.hasWorkout:
        return _buildWorkoutProgressBar(state);
    }
  }

  /// Строит прогресс-бар для дня отдыха
  Widget _buildRestDayBar(_TrainingProgressState state) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          state.text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  /// Строит прогресс-бар для дня без тренировки
  Widget _buildNoWorkoutBar(_TrainingProgressState state) {
    return _buildEnhancedProgressBar(0.0, Colors.red);
  }

  /// Строит прогресс-бар с прогрессом тренировки
  Widget _buildWorkoutProgressBar(_TrainingProgressState state) {
    return _buildEnhancedProgressBar(state.percentage, state.color);
  }


  /// Строит улучшенный прогресс-бар с автоматическим заполнением краев
  Widget _buildEnhancedProgressBar(double percentage, Color progressColor) {
    const double barHeight = 12.0;
    const double borderRadius = 6.0;
    const double edgeWidth = 8.0; // Ширина крайних областей
    
    debugPrint('ActivityProgressBar: building bar with percentage=$percentage, color=$progressColor');
    
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
            // Левая область - заполняется при наличии активности
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

/// Типы состояний прогресс-бара тренировок
enum _ProgressType {
  restDay,    // День отдыха
  noWorkout,  // День тренировки, но нет записанных тренировок
  hasWorkout, // День тренировки с записанными тренировками
}

/// Состояние прогресса тренировок
class _TrainingProgressState {
  final _ProgressType type;
  final double percentage;
  final Color color;
  final String text;

  const _TrainingProgressState({
    required this.type,
    required this.percentage,
    required this.color,
    required this.text,
  });
}
