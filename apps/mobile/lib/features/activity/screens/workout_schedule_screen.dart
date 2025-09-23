import 'package:flutter/material.dart';
import '../models/workout_schedule_model.dart';
import '../models/muscle_group_model.dart';
import '../services/workout_schedule_service.dart';
import '../../profile/services/performance_monitor.dart';

/// Экран настройки расписания тренировок
class WorkoutScheduleScreen extends StatefulWidget {
  final String userId;

  const WorkoutScheduleScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> with PerformanceMonitorMixin {
  late final WorkoutScheduleService _scheduleService;
  
  List<MuscleGroup> _muscleGroups = [];
  List<WorkoutSchedule> _schedule = [];
  bool _isLoading = false;
  String? _error;

  // Кэш для оптимизации
  final Map<int, WorkoutSchedule?> _scheduleCache = {};

  @override
  void initState() {
    super.initState();
    _scheduleService = WorkoutScheduleService(userId: widget.userId);
    _loadData();
  }

  /// Загрузка данных
  Future<void> _loadData() async {
    // Сразу показываем интерфейс с базовыми данными
    _muscleGroups = _getDefaultMuscleGroups();
    _schedule = [];
    _scheduleCache.clear();
    for (int day = 0; day < 7; day++) {
      _scheduleCache[day] = null;
    }
    setState(() {
      _isLoading = false;
      _error = null;
    });

    // Затем загружаем данные в фоне
    _loadDataInBackground();
  }

  /// Загрузка данных в фоне
  Future<void> _loadDataInBackground() async {
    try {
      // Пытаемся загрузить группы мышц
      try {
        final groups = await _scheduleService.getMuscleGroups().timeout(
          const Duration(seconds: 3),
        );
        if (mounted) {
          _muscleGroups = groups;
          setState(() {});
        }
      } catch (e) {
        debugPrint('Не удалось загрузить группы мышц: $e');
      }

      // Пытаемся загрузить расписание
      try {
        final schedule = await _scheduleService.getUserSchedule().timeout(
          const Duration(seconds: 3),
        );
        if (mounted) {
          _schedule = schedule;
          
          // Заполняем кэш для быстрого доступа
          _scheduleCache.clear();
          for (int day = 0; day < 7; day++) {
            try {
              _scheduleCache[day] = _schedule.firstWhere((s) => s.dayOfWeek == day);
            } catch (e) {
              _scheduleCache[day] = null;
            }
          }
          setState(() {});
        }
      } catch (e) {
        debugPrint('Не удалось загрузить расписание: $e');
        if (mounted) {
          setState(() {
            _error = 'Не удалось загрузить сохраненное расписание. Изменения будут сохранены локально.';
          });
        }
      }
    } catch (e) {
      debugPrint('Общая ошибка фоновой загрузки: $e');
    }
  }

  /// Обработка изменения дня
  Future<void> _onDayChanged(int dayOfWeek, {
    String? muscleGroupId,
    bool? isFullBody,
    bool? isActive,
  }) async {
    try {
      // Мгновенно обновляем UI для отзывчивости
      final existingSchedule = _scheduleCache[dayOfWeek];
      if (existingSchedule != null) {
        _scheduleCache[dayOfWeek] = existingSchedule.copyWith(
          muscleGroupId: muscleGroupId ?? existingSchedule.muscleGroupId,
          isFullBody: isFullBody ?? existingSchedule.isFullBody,
          isActive: isActive ?? existingSchedule.isActive,
        );
      } else if (isActive == true) {
        // Создаем новую запись для активного дня
        _scheduleCache[dayOfWeek] = WorkoutSchedule(
          id: 'temp_$dayOfWeek', // Временный ID
          userId: widget.userId,
          dayOfWeek: dayOfWeek,
          muscleGroupId: muscleGroupId,
          isFullBody: isFullBody ?? false,
          isActive: true,
        );
      }
      setState(() {});

      // Если есть ошибка подключения, не пытаемся сохранять на сервере
      if (_error != null && _error!.contains('временно недоступен')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сервис недоступен. Изменения не сохранены.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Затем сохраняем на сервере с таймаутом
      try {
        await _scheduleService.updateScheduleForDay(
          dayOfWeek: dayOfWeek,
          muscleGroupId: muscleGroupId,
          isFullBody: isFullBody,
          isActive: isActive,
        ).timeout(const Duration(seconds: 5));

        // Показываем уведомление об успехе
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Расписание на ${_getDayName(dayOfWeek)} обновлено'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        debugPrint('Ошибка сохранения на сервере: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Изменения сохранены локально. Синхронизация будет выполнена позже.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('Общая ошибка изменения расписания: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: ${e.toString().length > 50 ? "Проблема с подключением" : e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Получить название дня
  String _getDayName(int dayOfWeek) {
    const days = [
      'воскресенье', 'понедельник', 'вторник', 'среда', 
      'четверг', 'пятница', 'суббота'
    ];
    return days[dayOfWeek];
  }

  /// Получить базовые группы мышц как fallback
  List<MuscleGroup> _getDefaultMuscleGroups() {
    return [
      const MuscleGroup(id: 'legs', name: 'Ноги'),
      const MuscleGroup(id: 'back', name: 'Спина'),
      const MuscleGroup(id: 'biceps', name: 'Бицепс'),
      const MuscleGroup(id: 'shoulders', name: 'Плечи'),
      const MuscleGroup(id: 'triceps', name: 'Трицепс'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание тренировок'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  /// Строит основное содержимое экрана
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Показываем интерфейс даже при ошибках, но с предупреждением

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Предупреждение об ошибке (если есть)
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Обновить', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            // Заголовок
            const Text(
              'Выберите дни, в которые вы будете тренироваться',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Список дней недели (начинаем с понедельника)
            ...List.generate(7, (index) {
              // Преобразуем индекс: 0=понедельник, 1=вторник, ..., 6=воскресенье
              final dayOfWeek = (index + 1) % 7;
              return _buildDayCard(dayOfWeek);
            }),
          ],
        ),
      ),
    );
  }

  /// Строит карточку для дня недели
  Widget _buildDayCard(int dayOfWeek) {
    final schedule = _scheduleCache[dayOfWeek];
    final isActive = schedule?.isActive ?? false;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Заголовок дня с переключателем
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Название дня
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule?.dayName ?? _getDayName(dayOfWeek),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Text(
                            schedule?.workoutDescription ?? 'Тренировка',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Чекбокс активности дня
                  Checkbox(
                    value: isActive,
                    onChanged: (value) => _onDayChanged(
                      dayOfWeek,
                      isActive: value ?? false,
                    ),
                    activeColor: Colors.deepPurple,
                  ),
                ],
              ),
            ),

            // Настройки тренировки (показываются только если день активен)
            if (isActive) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildWorkoutSettings(dayOfWeek, schedule),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит настройки тренировки для дня
  Widget _buildWorkoutSettings(int dayOfWeek, WorkoutSchedule? schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тип тренировки:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Выбор между fullbody и группой мышц
        Row(
          children: [
            Expanded(
              child: _buildWorkoutTypeButton(
                label: 'Fullbody',
                isSelected: schedule?.isFullBody ?? false,
                onTap: () => _onDayChanged(
                  dayOfWeek,
                  isFullBody: true,
                  muscleGroupId: null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWorkoutTypeButton(
                label: 'Группа мышц',
                isSelected: !(schedule?.isFullBody ?? false),
                onTap: () => _onDayChanged(
                  dayOfWeek,
                  isFullBody: false,
                ),
              ),
            ),
          ],
        ),

        // Выбор группы мышц (показывается только если не fullbody)
        if (!(schedule?.isFullBody ?? false)) ...[
          const SizedBox(height: 16),
          const Text(
            'Группа мышц:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _muscleGroups.map((group) => _buildMuscleGroupChip(
              dayOfWeek,
              group,
              schedule?.muscleGroupId == group.id,
            )).toList(),
          ),
        ],
      ],
    );
  }

  /// Строит кнопку выбора типа тренировки
  Widget _buildWorkoutTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Строит чип для группы мышц
  Widget _buildMuscleGroupChip(int dayOfWeek, MuscleGroup group, bool isSelected) {
    return FilterChip(
      label: Text(group.name),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onDayChanged(
            dayOfWeek,
            muscleGroupId: group.id,
            isFullBody: false,
          );
        }
      },
      selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
      checkmarkColor: Colors.deepPurple,
    );
  }
}
