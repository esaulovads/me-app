import 'package:flutter/material.dart';
import '../services/workout_timer_service.dart';

/// Глобальный виджет таймера тренировки (отображается поверх всех экранов)
class GlobalWorkoutTimer extends StatelessWidget {
  final VoidCallback? onTap;

  const GlobalWorkoutTimer({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WorkoutTimerService.instance,
      builder: (context, child) {
        final timerService = WorkoutTimerService.instance;
        
        // Показываем только если есть активная тренировка
        if (!timerService.hasActiveWorkout || !timerService.isRunning) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.9),
                      Colors.green.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Иконка тренировки
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Информация о тренировке
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Тренировка активна',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            timerService.formattedTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Иконка для указания что можно нажать
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Обертка для экранов с глобальным таймером
class ScreenWithGlobalTimer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTimerTap;

  const ScreenWithGlobalTimer({
    Key? key,
    required this.child,
    this.onTimerTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        GlobalWorkoutTimer(onTap: onTimerTap),
      ],
    );
  }
}
