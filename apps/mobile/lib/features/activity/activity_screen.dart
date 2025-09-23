import 'dart:async';
import 'package:flutter/material.dart';
import 'services/activity_service.dart';
import 'services/workout_timer_service.dart';
import 'services/workout_schedule_service.dart';
import 'models/workout_model.dart';
import 'models/workout_schedule_model.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/workout_schedule_screen.dart';
import 'widgets/workout_timer_widget.dart';
import '../nutrition/widgets/date_navigation_header.dart';
import '../profile/services/performance_monitor.dart';

/// Экран отслеживания физической активности
class ActivityScreen extends StatefulWidget {
  final String userId;

  const ActivityScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with PerformanceMonitorMixin {
  late final ActivityService _activityService;
  late final WorkoutScheduleService _scheduleService;
  
  // Кэш для данных
  DateTime _selectedDate = DateTime.now();
  List<Workout>? _cachedWorkouts;
  WorkoutSchedule? _todaySchedule;
  
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(userId: widget.userId);
    _scheduleService = WorkoutScheduleService(userId: widget.userId);
    
    // Инициализируем сервис таймера
    WorkoutTimerService.instance.initialize(widget.userId);
    
    _initializeScreen();
  }

  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  /// Инициализация экрана с мониторингом
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Сначала загружаем основные данные (тренировки)
      await _loadWorkoutsForDate(_selectedDate);
      
      // Затем пытаемся загрузить расписание, но не блокируем основной функционал
      _loadTodaySchedule().catchError((e) {
        debugPrint('Не удалось загрузить расписание: $e');
        // Не показываем ошибку пользователю, просто логируем
      });
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Ошибка инициализации экрана активности: $e');
      setState(() {
        _error = 'Не удалось загрузить данные. Проверьте подключение к интернету.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Загрузка тренировок за выбранную дату
  Future<void> _loadWorkoutsForDate(DateTime date) async {
    try {
      final workouts = await _activityService.getWorkoutsByDate(date);
      
      if (mounted) {
        _cachedWorkouts = workouts;
        _error = null;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Ошибка загрузки тренировок: $e');
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить тренировки';
          _cachedWorkouts = [];
        });
      }
    }
  }

  /// Загрузка расписания на сегодня
  Future<void> _loadTodaySchedule() async {
    try {
      final schedule = await _scheduleService.getTodayWorkout();
      
      if (mounted) {
        _todaySchedule = schedule;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      // Не показываем ошибку пользователю, просто оставляем _todaySchedule = null
    }
  }

  /// Обработка выбора новой даты
  Future<void> _onDateSelected(DateTime date) async {
    if (date.isAtSameMomentAs(_selectedDate)) return;
    
    setState(() {
      _selectedDate = date;
      _cachedWorkouts = null; // Очищаем кэш для новой даты
    });
    
    await _loadWorkoutsForDate(date);
  }

  /// Обработка создания новой тренировки
  Future<void> _onCreateWorkout() async {
    try {
      // Создаем тренировку на сервере
      final newWorkout = await _activityService.createWorkout(
        date: _selectedDate,
        // Продолжительность и группы мышц будут определяться автоматически
      );
      
      // Мгновенно добавляем новую тренировку в локальный кэш
      if (_cachedWorkouts != null) {
        _cachedWorkouts!.add(newWorkout);
        setState(() {}); // Мгновенное обновление UI
      }
      
      // Очищаем кэш и перезагружаем данные для синхронизации
      await _activityService.clearCache();
      await _loadWorkoutsForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тренировка создана! Добавьте упражнения.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания тренировки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Обработка нажатия на тренировку
  Future<void> _onWorkoutTap(Workout workout) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          userId: widget.userId,
          workout: workout,
        ),
      ),
    );
    
    if (result == true || result == null) {
      // Перезагружаем данные после изменения тренировки или возвращения
      _cachedWorkouts = null;
      await _activityService.clearCache();
      await _loadWorkoutsForDate(_selectedDate);
    }
  }

  /// Начало тренировки
  Future<void> _onStartWorkout(Workout workout) async {
    try {
      // Мгновенно обновляем локальное состояние для отзывчивости UI
      final updatedWorkout = workout.copyWith(
        isActive: true,
        startedAt: DateTime.now(),
      );
      
      if (_cachedWorkouts != null) {
        final index = _cachedWorkouts!.indexWhere((w) => w.id == workout.id);
        if (index != -1) {
          _cachedWorkouts![index] = updatedWorkout;
          setState(() {}); // Мгновенное обновление UI
        }
      }
      
      // Затем обновляем на сервере
      await WorkoutTimerService.instance.startWorkout(workout);
      
      // Перезагружаем данные с сервера для синхронизации
      await _activityService.clearCache();
      await _loadWorkoutsForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тренировка начата! Таймер запущен.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // В случае ошибки откатываем изменения
      await _loadWorkoutsForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка начала тренировки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Завершение тренировки
  Future<void> _onFinishWorkout() async {
    try {
      // Находим активную тренировку для мгновенного обновления UI
      final activeWorkout = WorkoutTimerService.instance.activeWorkout;
      if (activeWorkout != null && _cachedWorkouts != null) {
        final index = _cachedWorkouts!.indexWhere((w) => w.id == activeWorkout.id);
        if (index != -1) {
          // Мгновенно обновляем локальное состояние
          final currentDuration = WorkoutTimerService.instance.durationInMinutes;
          final updatedWorkout = activeWorkout.copyWith(
            isActive: false,
            finishedAt: DateTime.now(),
            duration: currentDuration,
          );
          _cachedWorkouts![index] = updatedWorkout;
          setState(() {}); // Мгновенное обновление UI
        }
      }
      
      // Затем завершаем на сервере
      await WorkoutTimerService.instance.finishWorkout();
      
      // Перезагружаем данные с сервера для синхронизации
      await _activityService.clearCache();
      await _loadWorkoutsForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тренировка завершена!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // В случае ошибки откатываем изменения
      await _loadWorkoutsForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка завершения тренировки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Физическая активность'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateWorkout,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Строит основное содержимое экрана
  Widget _buildBody() {
    if (_isLoading && !_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _cachedWorkouts == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _cachedWorkouts = null;
                _initializeScreen();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

      return Column(
        children: [
          // Заголовок с навигацией по датам (как в питании)
          RepaintBoundary(
            child: DateNavigationHeader(
              selectedDate: _selectedDate,
              onPreviousDay: () => _onDateSelected(_selectedDate.subtract(const Duration(days: 1))),
              onNextDay: () => _onDateSelected(_selectedDate.add(const Duration(days: 1))),
              onDateTap: _selectDate,
            ),
          ),
          
          // Основное содержимое
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
        
        // Статистика (вычисляется из текущих тренировок)
        SliverToBoxAdapter(
          child: _buildStatisticsCard(),
        ),
        
        // Список тренировок
        SliverToBoxAdapter(
          child: _buildWorkoutsList(),
        ),
        
                // Отступ снизу для FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      );
    }
  
  /// Открытие датапикера для выбора конкретной даты
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ru', 'RU'),
      helpText: 'Выберите дату',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      await _onDateSelected(pickedDate);
    }
  }


  /// Строит карточку со статистикой
  Widget _buildStatisticsCard() {
    // Вычисляем статистику на основе текущих тренировок вместо загрузки с сервера
    final workouts = _cachedWorkouts ?? [];
    final totalWorkouts = workouts.length;
    final totalWeight = workouts.fold<double>(0.0, (sum, workout) => sum + workout.totalWeight);
    final averageWeight = totalWorkouts > 0 ? totalWeight / totalWorkouts : 0.0;
    
    return RepaintBoundary(
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
            // Заголовок с кнопкой настроек
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Статистика',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _onSettingsTap,
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.deepPurple,
                  ),
                  tooltip: 'Настройки расписания',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Тренировок',
                    totalWorkouts.toString(),
                    Icons.fitness_center,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Общий вес',
                    '${totalWeight.toStringAsFixed(1)} кг',
                    Icons.monitor_weight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Средний вес',
                    '${averageWeight.toStringAsFixed(1)} кг',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Упражнений',
                    '${workouts.fold<int>(0, (sum, w) => sum + w.exercises.length)}',
                    Icons.list,
                  ),
                ),
              ],
            ),

            // Информация о сегодняшней тренировке
            RepaintBoundary(
              child: _buildTodayWorkoutInfo(),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит элемент статистики
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.deepPurple,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Строит информацию о сегодняшней тренировке
  Widget _buildTodayWorkoutInfo() {
    if (_todaySchedule != null) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.today,
              color: Colors.deepPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Сегодня: ${_todaySchedule!.workoutDescription}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.weekend,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Сегодня день отдыха',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Строит список тренировок
  Widget _buildWorkoutsList() {
    final workouts = _cachedWorkouts ?? [];
    
    if (workouts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет тренировок за этот день',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Нажмите + чтобы добавить тренировку',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: workouts.map((workout) => _buildWorkoutItem(workout)).toList(),
    );
  }

  /// Строит элемент тренировки
  Widget _buildWorkoutItem(Workout workout) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Основная информация о тренировке
            InkWell(
              onTap: () => _onWorkoutTap(workout),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Иконка тренировки
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Информация о тренировке
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Тренировка ${workout.exercises.isNotEmpty ? "• ${workout.exercises.length} упражнений" : ""}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (workout.totalWeight > 0) ...[
                                Icon(
                                  Icons.monitor_weight,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${workout.totalWeight.toStringAsFixed(1)} кг',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (workout.duration != null) ...[
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workout.formattedDuration,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (workout.targetMuscleGroups.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              workout.formattedTargetMuscleGroups,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Кнопка удаления тренировки
                    IconButton(
                      onPressed: () => _deleteWorkout(workout),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      tooltip: 'Удалить тренировку',
                    ),
                  ],
                ),
              ),
            ),
            
            // Виджет таймера
            WorkoutTimerWidget(
              workout: workout,
              onStart: () => _onStartWorkout(workout),
              onFinish: _onFinishWorkout,
            ),
          ],
        ),
      ),
    );
  }



  /// Обработка нажатия на настройки
  Future<void> _onSettingsTap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutScheduleScreen(
          userId: widget.userId,
        ),
      ),
    );
    
    // После возврата из настроек перезагружаем данные
    await _loadWorkoutsForDate(_selectedDate);
    
    // Загружаем расписание отдельно, не блокируя основной функционал
    _loadTodaySchedule().catchError((e) {
      debugPrint('Не удалось обновить расписание: $e');
    });
  }

  /// Удаление тренировки с подтверждением
  Future<void> _deleteWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _activityService.deleteWorkout(workout.id, workout.date);
        
        // Обновляем данные
        _cachedWorkouts = null;
        await _activityService.clearCache();
        await _loadWorkoutsForDate(_selectedDate);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Тренировка удалена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
