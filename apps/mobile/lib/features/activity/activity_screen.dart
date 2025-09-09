import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'services/activity_service.dart';
import 'models/workout_model.dart';
import 'screens/workout_detail_screen.dart';
import '../nutrition/widgets/date_navigation_header.dart';
import '../nutrition/utils/date_formatter.dart';
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
  
  // Кэш для данных
  DateTime _selectedDate = DateTime.now();
  List<Workout>? _cachedWorkouts;
  
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  
  // Debounce для предотвращения частых обновлений
  Timer? _dataUpdateTimer;

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(userId: widget.userId);
    _initializeScreen();
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    _activityService.dispose();
    super.dispose();
  }

  /// Инициализация экрана с мониторингом
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Загружаем только тренировки сначала
      await _loadWorkoutsForDate(_selectedDate);
      
      // Статистика теперь вычисляется локально из тренировок
      
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
    // Отменяем предыдущий таймер если он есть
    _dataUpdateTimer?.cancel();
    
    _dataUpdateTimer = Timer(const Duration(milliseconds: 800), () async {
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
    });
  }

  /// Загрузка статистики тренировок

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
      // Создаем тренировку сразу без дополнительного экрана
      await _activityService.createWorkout(
        date: _selectedDate,
        // Продолжительность и группы мышц будут определяться автоматически
      );
      
      // Очищаем кэш и перезагружаем данные
      _cachedWorkouts = null;
      await _activityService.clearCache(); // Очищаем кэш сервиса
      
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

  /// Строит список тренировок
  Widget _buildWorkoutsList() {
    final workouts = _cachedWorkouts ?? [];
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workouts.isEmpty)
            Padding(
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
            )
          else
            ...workouts.map((workout) => _buildWorkoutItem(workout)).toList(),
        ],
      ),
    );
  }

  /// Строит элемент тренировки
  Widget _buildWorkoutItem(Workout workout) {
    return RepaintBoundary(
      child: InkWell(
        onTap: () => _onWorkoutTap(workout),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
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
    );
  }


  /// Форматирует текст о количестве тренировок
  String _getWorkoutsText(int count) {
    if (count == 1) return 'тренировка';
    if (count >= 2 && count <= 4) return 'тренировки';
    return 'тренировок';
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
