import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/activity_service.dart';
import '../services/workout_timer_service.dart';
import '../models/workout_model.dart';
import '../widgets/workout_timer_widget.dart';
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
  
  // Автосохранение с debounce
  final Map<String, Timer> _autoSaveTimers = {}; // Таймеры для каждого подхода
  final Map<String, bool> _savingStates = {}; // Состояние сохранения для каждого подхода
  static const Duration _autoSaveDelay = Duration(milliseconds: 1500); // Задержка перед сохранением
  
  // Управление спойлерами упражнений
  String? _expandedExerciseId; // ID развернутого упражнения (только одно может быть развернуто)

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(userId: widget.userId);
    _workout = widget.workout;
    _loadWorkoutExercises();
  }

  @override
  void dispose() {
    // Принудительно сохраняем все ожидающие изменения перед закрытием экрана
    _saveAllPendingChanges();
    
    // Очищаем все таймеры автосохранения
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    _savingStates.clear();
    
    _activityService.dispose();
    super.dispose();
  }

  /// Принудительно сохраняет все ожидающие изменения
  void _saveAllPendingChanges() {
    for (final entry in _autoSaveTimers.entries) {
      entry.value.cancel(); // Отменяем таймер
      // Запускаем сохранение немедленно (fire and forget)
      // Не ждем результат, так как dispose должен быть быстрым
    }
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

  /// Начало тренировки
  Future<void> _onStartWorkout() async {
    try {
      // Мгновенно обновляем локальное состояние
      setState(() {
        _workout = _workout.copyWith(
          isActive: true,
          startedAt: DateTime.now(),
        );
      });
      
      // Затем обновляем на сервере
      await WorkoutTimerService.instance.startWorkout(_workout);
      
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
      setState(() {
        _workout = _workout.copyWith(
          isActive: false,
          startedAt: null,
        );
      });
      
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
      // Мгновенно обновляем локальное состояние
      final currentDuration = WorkoutTimerService.instance.durationInMinutes;
      setState(() {
        _workout = _workout.copyWith(
          isActive: false,
          finishedAt: DateTime.now(),
          duration: currentDuration,
        );
      });
      
      // Затем завершаем на сервере
      final finishedWorkout = await WorkoutTimerService.instance.finishWorkout();
      
      // Обновляем с данными от сервера
      setState(() {
        _workout = finishedWorkout;
      });
      
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
      setState(() {
        _workout = _workout.copyWith(
          isActive: true,
          finishedAt: null,
        );
      });
      
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
        
        // Таймер тренировки
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: WorkoutTimerWidget(
              workout: _workout,
              onStart: _onStartWorkout,
              onFinish: _onFinishWorkout,
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
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
    );
  }

  /// Обработка добавления подхода к упражнению
  Future<void> _onAddSetToExercise(WorkoutExercise exercise) async {
    // Создаем новый подход с дефолтными значениями
    try {
      final newSet = await _activityService.createSet(
        workoutExerciseId: exercise.id,
        reps: 10,
        weight: 0.0,
      );
      
      // Обновляем локальное состояние без полной перезагрузки
      _addSetToLocalState(exercise, newSet);
      
      // Автоматически разворачиваем упражнение, если оно свернуто
      if (_expandedExerciseId != exercise.id) {
        setState(() {
          _expandedExerciseId = exercise.id;
        });
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления подхода: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Добавляет новый подход в локальное состояние
  void _addSetToLocalState(WorkoutExercise exercise, WorkoutSet newSet) {
    if (!mounted) return;
    
    setState(() {
      for (int i = 0; i < _exercises.length; i++) {
        if (_exercises[i].id == exercise.id) {
          final updatedSets = [..._exercises[i].sets, newSet];
          final exerciseTotalWeight = updatedSets.fold<double>(
            0.0, 
            (sum, s) => sum + s.totalWeight
          );
          
          _exercises[i] = _exercises[i].copyWith(
            sets: updatedSets,
            totalWeight: exerciseTotalWeight,
          );
          break;
        }
      }
    });
  }

  /// Автосохранение изменений подхода с debounce
  void _scheduleAutoSave(WorkoutSet set, {int? reps, double? weight}) {
    final setId = set.id;
    
    // Отменяем предыдущий таймер для этого подхода
    _autoSaveTimers[setId]?.cancel();
    
    // Обновляем локальное состояние немедленно для отзывчивости UI
    _updateLocalSetData(set, reps: reps, weight: weight);
    
    // Устанавливаем новый таймер для автосохранения
    _autoSaveTimers[setId] = Timer(_autoSaveDelay, () async {
      await _performAutoSave(set, reps: reps, weight: weight);
    });
  }

  /// Обновляет локальные данные подхода для немедленной отзывчивости UI
  void _updateLocalSetData(WorkoutSet set, {int? reps, double? weight}) {
    if (!mounted) return;
    
    setState(() {
      // Находим и обновляем подход в локальных данных
      for (int i = 0; i < _exercises.length; i++) {
        final exercise = _exercises[i];
        for (int j = 0; j < exercise.sets.length; j++) {
          if (exercise.sets[j].id == set.id) {
            final newReps = reps ?? set.reps;
            final newWeight = weight ?? set.weight;
            final totalWeight = (newReps * newWeight * exercise.equipmentCount).toDouble();
            
            // Обновляем подходы
            final updatedSets = exercise.sets.map((s) => s.id == set.id 
              ? s.copyWith(
                  reps: newReps,
                  weight: newWeight,
                  totalWeight: totalWeight,
                )
              : s
            ).toList();
            
            // Пересчитываем общий вес упражнения
            final exerciseTotalWeight = updatedSets.fold<double>(
              0.0, 
              (sum, s) => sum + s.totalWeight
            );
            
            _exercises[i] = exercise.copyWith(
              sets: updatedSets,
              totalWeight: exerciseTotalWeight,
            );
            return;
          }
        }
      }
    });
  }

  /// Выполняет автосохранение на сервере
  Future<void> _performAutoSave(WorkoutSet set, {int? reps, double? weight}) async {
    final setId = set.id;
    
    if (!mounted) return;
    
    // Устанавливаем состояние сохранения
    setState(() {
      _savingStates[setId] = true;
    });
    
    try {
      await _activityService.updateSet(
        setId: setId,
        reps: reps ?? set.reps,
        weight: weight ?? set.weight,
      );
      
      // Убираем состояние сохранения при успехе
      if (mounted) {
        setState(() {
          _savingStates[setId] = false;
        });
      }
      
      // Успешное сохранение - не показываем уведомления
      
    } catch (e) {
      // Убираем состояние сохранения при ошибке
      if (mounted) {
        setState(() {
          _savingStates[setId] = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () => _scheduleAutoSave(set, reps: reps, weight: weight),
            ),
          ),
        );
      }
    } finally {
      // Удаляем таймер после выполнения
      _autoSaveTimers.remove(setId);
    }
  }

  /// Обработка удаления подхода
  Future<void> _onDeleteSet(WorkoutSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить подход?'),
        content: const Text('Это действие нельзя будет отменить.'),
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
    
    if (confirmed == true) {
      try {
        await _activityService.deleteSet(set.id);
        
        // Обновляем локальное состояние без полной перезагрузки
        _removeSetFromLocalState(set);
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления подхода: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Удаляет подход из локального состояния
  void _removeSetFromLocalState(WorkoutSet set) {
    if (!mounted) return;
    
    setState(() {
      for (int i = 0; i < _exercises.length; i++) {
        final exercise = _exercises[i];
        final updatedSets = exercise.sets.where((s) => s.id != set.id).toList();
        
        if (updatedSets.length != exercise.sets.length) {
          // Подход был найден и удален, пересчитываем общий вес
          final exerciseTotalWeight = updatedSets.fold<double>(
            0.0, 
            (sum, s) => sum + s.totalWeight
          );
          
          _exercises[i] = exercise.copyWith(
            sets: updatedSets,
            totalWeight: exerciseTotalWeight,
          );
          break;
        }
      }
    });
  }

  /// Обработка удаления упражнения из тренировки
  Future<void> _onDeleteExercise(WorkoutExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: Text(
          'Упражнение "${exercise.exerciseName}" и все его подходы будут удалены из тренировки. '
          'Это действие нельзя будет отменить.',
        ),
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
    
    if (confirmed == true) {
      try {
        await _activityService.removeExerciseFromWorkout(exercise.id);
        
        // Обновляем локальное состояние без полной перезагрузки
        _removeExerciseFromLocalState(exercise);
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления упражнения: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Удаляет упражнение из локального состояния
  void _removeExerciseFromLocalState(WorkoutExercise exercise) {
    if (!mounted) return;
    
    setState(() {
      _exercises.removeWhere((ex) => ex.id == exercise.id);
      
      // Если удаленное упражнение было развернуто, сворачиваем
      if (_expandedExerciseId == exercise.id) {
        _expandedExerciseId = null;
      }
    });
  }

  /// Строит элемент упражнения со спойлером
  Widget _buildExerciseItem(WorkoutExercise exercise) {
    final isExpanded = _expandedExerciseId == exercise.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок упражнения с кнопкой разворота
          InkWell(
            onTap: () {
              setState(() {
                _expandedExerciseId = isExpanded ? null : exercise.id;
              });
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              exercise.targetMuscleGroup,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (exercise.sets.isNotEmpty) ...[
                              Text(
                                ' • ${exercise.sets.length} подходов',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (exercise.totalWeight > 0) ...[
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
                    const SizedBox(width: 8),
                  ],
                  // Кнопка удаления упражнения
                  IconButton(
                    onPressed: () => _onDeleteExercise(exercise),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red.withOpacity(0.7),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: 'Удалить упражнение',
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Развернутое содержимое
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Компактные подходы
                  if (exercise.sets.isNotEmpty) ...[
                    ...exercise.sets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final set = entry.value;
                      return _buildCompactSetItem(exercise, set, index);
                    }).toList(),
                    const SizedBox(height: 12),
                  ],
                  
                  // Кнопка добавления подхода
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _onAddSetToExercise(exercise),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(exercise.sets.isEmpty ? 'Добавить первый подход' : 'Добавить подход'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Строит компактный элемент подхода в одну строку
  Widget _buildCompactSetItem(WorkoutExercise exercise, WorkoutSet set, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Номер подхода
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Повторения
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Повторения',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  initialValue: set.reps.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final reps = int.tryParse(value.trim()) ?? set.reps;
                    if (reps >= 0 && reps != set.reps) {
                      _scheduleAutoSave(set, reps: reps);
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Вес
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Вес (кг)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  initialValue: set.weight.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value.trim()) ?? set.weight;
                    if (weight >= 0.0 && weight != set.weight) {
                      _scheduleAutoSave(set, weight: weight);
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Общий вес
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Итого',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: _savingStates[set.id] == true 
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _savingStates[set.id] == true 
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.deepPurple.withOpacity(0.3)
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_savingStates[set.id] == true) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          '${set.totalWeight.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _savingStates[set.id] == true 
                              ? Colors.orange
                              : Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Кнопка удаления
          IconButton(
            onPressed: () => _onDeleteSet(set),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Строит элемент подхода для inline-редактирования (legacy)
  Widget _buildInlineSetItem(WorkoutExercise exercise, WorkoutSet set, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Заголовок подхода
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Подход ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _onDeleteSet(set),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Поля редактирования
          Row(
            children: [
              // Повторения
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Повторения',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: set.reps.toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final reps = int.tryParse(value.trim()) ?? set.reps;
                        if (reps >= 0 && reps != set.reps) {
                          _scheduleAutoSave(set, reps: reps);
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Вес
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вес (кг)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: set.weight.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final weight = double.tryParse(value.trim()) ?? set.weight;
                        if (weight >= 0.0 && weight != set.weight) {
                          _scheduleAutoSave(set, weight: weight);
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Общий вес
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Итого',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: _savingStates[set.id] == true 
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _savingStates[set.id] == true 
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.deepPurple.withOpacity(0.3)
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_savingStates[set.id] == true) ...[
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${set.totalWeight.toStringAsFixed(1)} кг',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _savingStates[set.id] == true 
                                ? Colors.orange
                                : Colors.deepPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
