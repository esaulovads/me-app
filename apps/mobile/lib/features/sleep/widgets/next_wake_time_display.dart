import 'package:flutter/material.dart';
import '../models/sleep_schedule_model.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/models/profile_model.dart';

/// Виджет для отображения планируемого времени завтрашнего пробуждения
class NextWakeTimeDisplay extends StatefulWidget {
  final SleepSchedule schedule;
  final VoidCallback onEditPressed;
  final String userId;

  const NextWakeTimeDisplay({
    Key? key,
    required this.schedule,
    required this.onEditPressed,
    required this.userId,
  }) : super(key: key);

  @override
  State<NextWakeTimeDisplay> createState() => _NextWakeTimeDisplayState();
}

class _NextWakeTimeDisplayState extends State<NextWakeTimeDisplay> {
  double? _recommendedSleepDuration;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Загружает профиль пользователя для получения рекомендуемой продолжительности сна
  Future<void> _loadProfile() async {
    try {
      final profileService = ProfileService(userId: widget.userId);
      final profile = await profileService.getProfile();
      
      if (mounted) {
        setState(() {
          _recommendedSleepDuration = profile.recommendedSleepDuration ?? 8.0;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки профиля для расчета времени сна: $e');
      if (mounted) {
        setState(() {
          _recommendedSleepDuration = 8.0; // Значение по умолчанию
          _isLoadingProfile = false;
        });
      }
    }
  }

  /// Получает время пробуждения на завтра
  String? _getTomorrowWakeTime() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowWeekday = tomorrow.weekday; // 1 = понедельник, 7 = воскресенье
    return widget.schedule.getWakeTimeForDay(tomorrowWeekday);
  }

  /// Рассчитывает рекомендуемое время засыпания
  String? _getRecommendedBedtime() {
    if (_recommendedSleepDuration == null) return null;
    
    final wakeTimeString = _getTomorrowWakeTime();
    if (wakeTimeString == null) return null;
    
    try {
      final parts = wakeTimeString.split(':');
      if (parts.length == 2) {
        final wakeHour = int.parse(parts[0]);
        final wakeMinute = int.parse(parts[1]);
        
        // Создаем время пробуждения на завтра
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final wakeTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, wakeHour, wakeMinute);
        
        // Вычитаем рекомендуемую продолжительность сна
        final sleepDurationMinutes = (_recommendedSleepDuration! * 60).round();
        final bedtime = wakeTime.subtract(Duration(minutes: sleepDurationMinutes));
        
        // Форматируем время
        return '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Ошибка расчета времени засыпания: $e');
    }
    return null;
  }

  /// Получает название завтрашнего дня
  String _getTomorrowDayName() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    const dayNames = [
      'понедельник',
      'вторник', 
      'среду',
      'четверг',
      'пятницу',
      'субботу',
      'воскресенье'
    ];
    return dayNames[tomorrow.weekday - 1];
  }

  /// Форматирует время для отображения
  String _formatDisplayTime(String? time) {
    if (time == null) return 'Не настроено';
    
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Ошибка времени';
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.schedule.isEnabled) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.bedtime_outlined, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Расписание сна',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onEditPressed,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Настроить расписание',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Расписание сна отключено',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onEditPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Настроить расписание'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tomorrowWakeTime = _getTomorrowWakeTime();
    final tomorrowDayName = _getTomorrowDayName();
    final displayWakeTime = _formatDisplayTime(tomorrowWakeTime);
    final recommendedBedtime = _getRecommendedBedtime();
    final displayBedtime = _formatDisplayTime(recommendedBedtime);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Расписание сна',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onEditPressed,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Изменить расписание',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Основная информация о рекомендуемом времени засыпания
            if (!_isLoadingProfile && recommendedBedtime != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bedtime,
                          color: Colors.purple.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Рекомендуемое время засыпания',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayBedtime,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'сегодня вечером',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_isLoadingProfile) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Загрузка рекомендаций...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Информация о времени пробуждения (теперь меньше)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm,
                    color: Colors.indigo.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Пробуждение завтра в $tomorrowDayName: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  Text(
                    displayWakeTime,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ],
              ),
            ),
            

          ],
        ),
      ),
    );
  }


}