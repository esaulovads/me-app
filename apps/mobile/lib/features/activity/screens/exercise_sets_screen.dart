import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/activity_service.dart';
import '../models/workout_model.dart';

/// Экран управления подходами упражнения
class ExerciseSetsScreen extends StatefulWidget {
  final String userId;
  final WorkoutExercise workoutExercise;

  const ExerciseSetsScreen({
    Key? key,
    required this.userId,
    required this.workoutExercise,
  }) : super(key: key);

  @override
  State<ExerciseSetsScreen> createState() => _ExerciseSetsScreenState();
}

class _ExerciseSetsScreenState extends State<ExerciseSetsScreen> {
  late final ActivityService _activityService;
  
  // Данные подходов
  List<WorkoutSet> _sets = [];
  
  // Состояние загрузки
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(userId: widget.userId);
    _sets = List.from(widget.workoutExercise.sets);
    
    // Если нет подходов, добавляем 3 по умолчанию
    if (_sets.isEmpty) {
      _addDefaultSets();
    }
  }

  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  /// Добавляет 3 подхода по умолчанию
  void _addDefaultSets() {
    setState(() {
      for (int i = 0; i < 3; i++) {
        _sets.add(WorkoutSet(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}_$i',
          workoutExerciseId: widget.workoutExercise.id,
          reps: 10,
          weight: 0.0,
          totalWeight: 0.0,
        ));
      }
    });
  }

  /// Добавляет новый подход
  void _addSet() {
    setState(() {
      // Берем данные из последнего подхода как основу
      final lastSet = _sets.isNotEmpty ? _sets.last : null;
      
      _sets.add(WorkoutSet(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        workoutExerciseId: widget.workoutExercise.id,
        reps: lastSet?.reps ?? 10,
        weight: lastSet?.weight ?? 0.0,
        totalWeight: 0.0,
      ));
    });
  }

  /// Удаляет подход
  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
    });
  }

  /// Обновляет данные подхода
  void _updateSet(int index, {int? reps, double? weight}) {
    setState(() {
      final set = _sets[index];
      final newReps = reps ?? set.reps;
      final newWeight = weight ?? set.weight;
      
      // Вычисляем общий вес: повторения × вес × количество снарядов
      final totalWeight = (newReps * newWeight * widget.workoutExercise.equipmentCount).toDouble();
      
      _sets[index] = set.copyWith(
        reps: newReps,
        weight: newWeight,
        totalWeight: totalWeight,
      );
    });
  }

  /// Сохраняет подходы на сервере
  Future<void> _saveSets() async {
    setState(() => _isLoading = true);
    
    try {
      // Подготавливаем данные для массового создания
      final setsData = _sets.map((set) => {
        'reps': set.reps,
        'weight': set.weight,
      }).toList();
      
      await _activityService.createBulkSets(
        workoutExerciseId: widget.workoutExercise.id,
        sets: setsData,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true для обновления данных
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Подходы сохранены успешно!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения подходов: $e'),
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
        title: Text(widget.workoutExercise.exerciseName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSets,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация об упражнении
          _buildExerciseInfo(),
          
          // Список подходов
          Expanded(
            child: _buildSetsList(),
          ),
          
          // Кнопка добавления подхода
          _buildAddSetButton(),
        ],
      ),
    );
  }

  /// Строит информацию об упражнении
  Widget _buildExerciseInfo() {
    final totalWeight = _sets.fold<double>(0.0, (sum, set) => sum + set.totalWeight);
    
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
          // Название и группа мышц
          Text(
            widget.workoutExercise.exerciseName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.workoutExercise.targetMuscleGroup,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Статистика
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Подходов',
                  _sets.length.toString(),
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
              if (widget.workoutExercise.equipmentCount > 1)
                Expanded(
                  child: _buildStatItem(
                    'Снарядов',
                    widget.workoutExercise.equipmentCount.toString(),
                    Icons.fitness_center,
                  ),
                ),
            ],
          ),
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

  /// Строит список подходов
  Widget _buildSetsList() {
    if (_sets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет подходов',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _sets.length,
      itemBuilder: (context, index) {
        final set = _sets[index];
        return _buildSetItem(set, index);
      },
    );
  }

  /// Строит элемент подхода
  Widget _buildSetItem(WorkoutSet set, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Заголовок подхода
            Row(
              children: [
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
                Expanded(
                  child: Text(
                    'Подход ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_sets.length > 1)
                  IconButton(
                    onPressed: () => _removeSet(index),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Поля ввода
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
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: TextEditingController(text: set.reps.toString()),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          final reps = int.tryParse(value.trim()) ?? set.reps;
                          if (reps >= 0) {
                            _updateSet(index, reps: reps);
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
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        controller: TextEditingController(text: set.weight.toString()),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          final weight = double.tryParse(value.trim()) ?? set.weight;
                          if (weight >= 0.0) {
                            _updateSet(index, weight: weight);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Общий вес подхода
            if (set.totalWeight > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Общий вес подхода:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${set.totalWeight.toStringAsFixed(1)} кг',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит кнопку добавления подхода
  Widget _buildAddSetButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _addSet,
          icon: const Icon(Icons.add),
          label: const Text('Добавить подход'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            foregroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
