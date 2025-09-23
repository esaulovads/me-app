import 'package:flutter/material.dart';
import '../services/workout_timer_service.dart';
import '../models/workout_model.dart';

/// Виджет таймера тренировки
class WorkoutTimerWidget extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onStart;
  final VoidCallback? onFinish;
  final bool showOnlyTimer; // Показывать только таймер без кнопок

  const WorkoutTimerWidget({
    Key? key,
    required this.workout,
    this.onStart,
    this.onFinish,
    this.showOnlyTimer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WorkoutTimerService.instance,
      builder: (context, child) {
        final timerService = WorkoutTimerService.instance;
        final isCurrentWorkoutActive = timerService.activeWorkout?.id == workout.id;
        
        // Если это активная тренировка и таймер запущен
        if (isCurrentWorkoutActive && timerService.isRunning) {
          return _buildRunningTimer(context, timerService);
        }
        
        // Если тренировка завершена (есть продолжительность)
        if (workout.duration != null && workout.duration! > 0) {
          return _buildCompletedWorkout(context);
        }
        
        // Если тренировка не начата и нет другой активной тренировки
        if (!timerService.hasActiveWorkout && !showOnlyTimer) {
          return _buildStartButton(context);
        }
        
        // Если есть другая активная тренировка
        if (timerService.hasActiveWorkout && !isCurrentWorkoutActive && !showOnlyTimer) {
          return _buildDisabledState(context);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  /// Виджет запущенного таймера
  Widget _buildRunningTimer(BuildContext context, WorkoutTimerService timerService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Column(
        children: [
          // Таймер
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                timerService.formattedTime,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          
          if (!showOnlyTimer) ...[
            const SizedBox(height: 12),
            // Кнопка завершения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onFinish,
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text(
                  'Завершить тренировку',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Виджет завершенной тренировки (не показываем ничего)
  Widget _buildCompletedWorkout(BuildContext context) {
    return const SizedBox.shrink(); // Не показываем блок для завершенных тренировок
  }

  /// Кнопка начала тренировки
  Widget _buildStartButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text(
          'Начать тренировку',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Состояние когда другая тренировка активна
  Widget _buildDisabledState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Завершите текущую тренировку',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
