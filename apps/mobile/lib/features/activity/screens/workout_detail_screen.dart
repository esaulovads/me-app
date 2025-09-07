import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import '../models/workout_model.dart';
import 'exercise_selection_screen.dart';
import 'exercise_sets_screen.dart';

/// Экран детализации тренировки
class WorkoutDetailScreen extends StatefulWidget {
  final String userId;
  final Workout workout;

  const WorkoutDetailScreen({
    Key? key,
    required this.userId,
    required this.workout,
  }) : super(key: key);

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late final ActivityService _activityService;
  
  // Данные тренировки
  late Workout _workout;
  List<WorkoutExercise> _exercises = [];
  
  // Состояние загрузки
  bool _isLoading = false;
  bool _isLoadingExercises = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(userId: widget.userId);
    _workout = widget.workout;
    _loadWorkoutExercises();
  }

  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  /// Загрузка упражнений тренировки
  Future<void> _loadWorkoutExercises() async {
    setState(() => _isLoadingExercises = true);
    
    try {
      final exercises = await _activityService.getWorkoutExercises(_workout.id);
      
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки упражнений тренировки: $e');
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить упражнения';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExercises = false);
      }
    }
  }

  /// Обработка добавления упражнений
  Future<void> _onAddExercises() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSelectionScreen(
          userId: widget.userId,
          workoutId: _workout.id,
        ),
      ),
    );
    
    if (result == true) {
      // Перезагружаем упражнения после добавления
      await _loadWorkoutExercises();
    }
  }

  /// Обработка удаления тренировки
  Future<void> _onDeleteWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text('Это действие нельзя будет отменить. Все упражнения и подходы будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _activityService.deleteWorkout(_workout.id, _workout.date);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true для обновления данных
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
            content: Text('Ошибка удаления тренировки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировка'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _onDeleteWorkout,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить тренировку',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddExercises,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Строит основное содержимое экрана
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Информация о тренировке
        SliverToBoxAdapter(
          child: _buildWorkoutInfo(),
        ),
        
        // Список упражнений
        SliverToBoxAdapter(
          child: _buildExercisesList(),
        ),
        
        // Отступ снизу для FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  /// Строит информацию о тренировке
  Widget _buildWorkoutInfo() {
    return Container(
      margin: const EdgeInsets.all(16.0),
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
          // Дата тренировки
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.deepPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(_workout.date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Статистика тренировки
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Упражнений',
                  _exercises.length.toString(),
                  Icons.fitness_center,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Общий вес',
                  '${_workout.totalWeight.toStringAsFixed(1)} кг',
                  Icons.monitor_weight,
                ),
              ),
              if (_workout.duration != null)
                Expanded(
                  child: _buildStatItem(
                    'Время',
                    _workout.formattedDuration,
                    Icons.schedule,
                  ),
                ),
            ],
          ),
          
          // Целевые группы мышц
          if (_workout.targetMuscleGroups.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Colors.deepPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Целевые группы мышц:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _workout.formattedTargetMuscleGroups,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Строит список упражнений
  Widget _buildExercisesList() {
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Упражнения',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_exercises.isNotEmpty)
                  Text(
                    '${_exercises.length} ${_getExercisesText(_exercises.length)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          
          if (_isLoadingExercises)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadWorkoutExercises,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          else if (_exercises.isEmpty)
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
                      'Нет упражнений в тренировке',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите + чтобы добавить упражнения',
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
            ..._exercises.map((exercise) => _buildExerciseItem(exercise)).toList(),
        ],
      ),
    );
  }

  /// Обработка нажатия на упражнение
  Future<void> _onExerciseTap(WorkoutExercise exercise) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSetsScreen(
          userId: widget.userId,
          workoutExercise: exercise,
        ),
      ),
    );
    
    if (result == true) {
      // Перезагружаем упражнения после изменения подходов
      await _loadWorkoutExercises();
    }
  }

  /// Строит элемент упражнения
  Widget _buildExerciseItem(WorkoutExercise exercise) {
    return InkWell(
      onTap: () => _onExerciseTap(exercise),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название упражнения
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (exercise.totalWeight > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${exercise.totalWeight.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
            ],
          ),
          
          // Группа мышц
          const SizedBox(height: 4),
          Text(
            exercise.targetMuscleGroup,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          // Подсказка о том, что можно нажать
          if (exercise.sets.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Нажмите для добавления подходов',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Подходы
          if (exercise.sets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Подходы:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...exercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${set.reps} повторений × ${set.weight.toStringAsFixed(1)} кг',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${set.totalWeight.toStringAsFixed(1)} кг',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Нет подходов',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// Форматирует дату в читаемый вид
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Сегодня';
    } else if (selectedDay == yesterday) {
      return 'Вчера';
    } else {
      const months = [
        'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  /// Форматирует текст о количестве упражнений
  String _getExercisesText(int count) {
    if (count == 1) return 'упражнение';
    if (count >= 2 && count <= 4) return 'упражнения';
    return 'упражнений';
  }
}
