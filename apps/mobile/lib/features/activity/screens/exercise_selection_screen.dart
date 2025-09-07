import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import '../models/exercise_model.dart';

/// Экран выбора упражнений для добавления в тренировку
class ExerciseSelectionScreen extends StatefulWidget {
  final String userId;
  final String workoutId;

  const ExerciseSelectionScreen({
    Key? key,
    required this.userId,
    required this.workoutId,
  }) : super(key: key);

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late final ActivityService _activityService;
  
  // Контроллеры
  final _searchController = TextEditingController();
  
  // Данные
  List<Exercise> _exercises = [];
  List<String> _muscleGroups = [];
  String? _selectedMuscleGroup;
  final Set<String> _selectedExerciseIds = {};
  
  // Состояние загрузки
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isAddingExercises = false;
  bool _hasMore = true;
  String? _error;
  
  // Пагинация
  int _offset = 0;
  final int _limit = 20;
  
  // Поиск
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(userId: widget.userId);
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _activityService.dispose();
    super.dispose();
  }

  /// Инициализация экрана
  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем группы мышц и упражнения параллельно
      await Future.wait([
        _loadMuscleGroups(),
        _loadExercises(reset: true),
      ]);
    } catch (e) {
      debugPrint('Ошибка инициализации экрана выбора упражнений: $e');
      setState(() {
        _error = 'Не удалось загрузить данные. Проверьте подключение к интернету.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Загрузка групп мышц
  Future<void> _loadMuscleGroups() async {
    try {
      final muscleGroups = await _activityService.getMuscleGroups();
      
      if (mounted) {
        setState(() {
          _muscleGroups = muscleGroups;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки групп мышц: $e');
      // Не критично, продолжаем без фильтра
    }
  }

  /// Загрузка упражнений
  Future<void> _loadExercises({bool reset = false}) async {
    if (reset) {
      setState(() {
        _offset = 0;
        _hasMore = true;
        _exercises.clear();
      });
    }
    
    if (!_hasMore) return;
    
    setState(() => reset ? _isLoading = true : _isLoadingMore = true);
    
    try {
      // Очищаем кэш перед первой загрузкой
      if (reset) {
        await _activityService.clearCache();
      }
      
      final response = await _activityService.getExercises(
        limit: _limit,
        offset: _offset,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        muscleGroup: _selectedMuscleGroup,
      );
      
      debugPrint('Загружено упражнений: ${response.exercises.length}');
      
      if (mounted) {
        setState(() {
          if (reset) {
            _exercises = response.exercises;
          } else {
            _exercises.addAll(response.exercises);
          }
          _offset += response.exercises.length;
          _hasMore = response.hasMore;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки упражнений: $e');
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить упражнения';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Обработка поиска
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // Debounce поиска
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query && mounted) {
        _loadExercises(reset: true);
      }
    });
  }

  /// Обработка изменения фильтра группы мышц
  void _onMuscleGroupChanged(String? muscleGroup) {
    setState(() {
      _selectedMuscleGroup = muscleGroup;
    });
    
    _loadExercises(reset: true);
  }

  /// Обработка добавления выбранных упражнений
  Future<void> _addSelectedExercises() async {
    if (_selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одно упражнение'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isAddingExercises = true);
    
    try {
      // Добавляем каждое выбранное упражнение
      for (final exerciseId in _selectedExerciseIds) {
        await _activityService.addExerciseToWorkout(widget.workoutId, exerciseId);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true для обновления данных
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добавлено ${_selectedExerciseIds.length} упражнений'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления упражнений: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingExercises = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор упражнений'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedExerciseIds.isNotEmpty)
            TextButton(
              onPressed: _isAddingExercises ? null : _addSelectedExercises,
              child: _isAddingExercises
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Добавить (${_selectedExerciseIds.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Поиск и фильтры
          _buildSearchAndFilters(),
          
          // Список упражнений
          Expanded(
            child: _buildExercisesList(),
          ),
        ],
      ),
    );
  }

  /// Строит секцию поиска и фильтров
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          // Поиск
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Поиск упражнений...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          
          // Фильтр по группе мышц
          if (_muscleGroups.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Кнопка "Все"
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: const Text('Все'),
                      selected: _selectedMuscleGroup == null,
                      onSelected: (selected) {
                        if (selected) {
                          _onMuscleGroupChanged(null);
                        }
                      },
                      selectedColor: Colors.deepPurple.withOpacity(0.2),
                      checkmarkColor: Colors.deepPurple,
                    ),
                  ),
                  
                  // Группы мышц
                  ..._muscleGroups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(group),
                        selected: _selectedMuscleGroup == group,
                        onSelected: (selected) {
                          _onMuscleGroupChanged(selected ? group : null);
                        },
                        selectedColor: Colors.deepPurple.withOpacity(0.2),
                        checkmarkColor: Colors.deepPurple,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Строит список упражнений
  Widget _buildExercisesList() {
    if (_isLoading && _exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _exercises.isEmpty) {
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
              onPressed: () => _loadExercises(reset: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Упражнения не найдены',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            !_isLoadingMore &&
            _hasMore) {
          _loadExercises();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _exercises.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _exercises.length) {
            return _isLoadingMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final exercise = _exercises[index];
          final isSelected = _selectedExerciseIds.contains(exercise.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedExerciseIds.add(exercise.id);
                  } else {
                    _selectedExerciseIds.remove(exercise.id);
                  }
                });
              },
              title: Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    exercise.targetMuscleGroup,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (exercise.equipmentCount > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Снарядов: ${exercise.equipmentCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
              controlAffinity: ListTileControlAffinity.trailing,
              activeColor: Colors.deepPurple,
            ),
          );
        },
      ),
    );
  }
}
