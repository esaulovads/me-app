import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/date_navigation_header.dart';
import 'services/nutrition_service.dart';
import 'models/meal_model.dart';
import 'screens/dish_selection_screen.dart';

class NutritionScreen extends StatefulWidget {
  final String userId;

  const NutritionScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late final NutritionService _nutritionService;
  DateTime _selectedDate = DateTime.now();
  
  // Кэш для данных питания
  final Map<String, List<Meal>> _mealsCache = {};
  final Map<String, DailySummary> _summaryCache = {};
  
  // Состояние загрузки
  bool _isLoading = false;
  String? _error;
  
  // Debounce для предотвращения частых запросов при быстрой смене дат
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(userId: widget.userId);
    _loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nutritionService.dispose();
    super.dispose();
  }

  // Ленивая загрузка данных для выбранной даты
  Future<void> _loadDataForDate(DateTime date) async {
    final dateKey = _formatDateKey(date);
    
    // Если данные уже в кэше, не загружаем повторно
    if (_mealsCache.containsKey(dateKey) && _summaryCache.containsKey(dateKey)) {
      return;
    }

    // Отменяем предыдущий таймер
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        // Загружаем данные параллельно
        final results = await Future.wait([
          _nutritionService.getMealsForDate(date),
          _nutritionService.getDailySummary(date),
        ]);

        if (mounted) {
          // Кэшируем результаты
          _mealsCache[dateKey] = results[0] as List<Meal>;
          _summaryCache[dateKey] = results[1] as DailySummary;
          
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = e.toString();
          });
        }
      }
    });
  }

  // Форматирование даты для ключа кэша
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Переход к предыдущему дню
  void _goToPreviousDay() {
    final newDate = _selectedDate.subtract(const Duration(days: 1));
    setState(() {
      _selectedDate = newDate;
    });
    _loadDataForDate(newDate);
  }

  // Переход к следующему дню
  void _goToNextDay() {
    final newDate = _selectedDate.add(const Duration(days: 1));
    setState(() {
      _selectedDate = newDate;
    });
    _loadDataForDate(newDate);
  }

  // Открытие датапикера для выбора конкретной даты
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru', 'RU'),
      helpText: 'Выберите дату',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _loadDataForDate(pickedDate);
    }
  }

  // Получение данных из кэша с сортировкой по времени
  List<Meal> _getCachedMeals() {
    final dateKey = _formatDateKey(_selectedDate);
    final meals = List<Meal>.from(_mealsCache[dateKey] ?? []);
    
    // Сортируем приёмы пищи по времени от раннего к позднему
    meals.sort((a, b) => a.time.compareTo(b.time));
    
    return meals;
  }

  DailySummary? _getCachedSummary() {
    final dateKey = _formatDateKey(_selectedDate);
    return _summaryCache[dateKey];
  }

  // Создание нового приёма пищи
  Future<void> _createNewMeal() async {
    // Создаём новый приём пищи с текущим временем, но с датой выбранного дня
    final mealTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _nutritionService.createMeal(mealTime);
      
      // Очищаем кэш для текущей даты и перезагружаем данные
      final dateKey = _formatDateKey(_selectedDate);
      _mealsCache.remove(dateKey);
      _summaryCache.remove(dateKey);
      
      await _loadDataForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Приём пищи создан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания приёма пищи: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Переход к экрану выбора блюд
  Future<void> _navigateToDishSelection(String mealId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DishSelectionScreen(
          userId: widget.userId,
          mealId: mealId,
        ),
      ),
    );

    // Если вернулись с изменениями, перезагружаем данные
    if (result == true) {
      await _loadDataForDate(_selectedDate);
    }
  }

  // Удаление приёма пищи
  Future<void> _deleteMeal(Meal meal) async {
    // Показываем диалог подтверждения
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить приём пищи?'),
          content: Text('Вы действительно хотите удалить приём пищи в ${meal.formattedTime}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _nutritionService.deleteMeal(meal.id, meal.time);
      
      // Очищаем кэш для текущей даты и перезагружаем данные
      final dateKey = _formatDateKey(_selectedDate);
      _mealsCache.remove(dateKey);
      _summaryCache.remove(dateKey);
      
      await _loadDataForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Приём пищи удалён'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления приёма пищи: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Редактирование времени приёма пищи
  Future<void> _editMealTime(Meal meal) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(meal.time),
      helpText: 'Выберите время приёма пищи',
      cancelText: 'Отмена',
      confirmText: 'Сохранить',
    );

    if (pickedTime == null) return;

    // Создаём новую дату с выбранным временем но той же датой
    final newDateTime = DateTime(
      meal.time.year,
      meal.time.month,
      meal.time.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Если время не изменилось, ничего не делаем
    if (newDateTime.isAtSameMomentAs(meal.time)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _nutritionService.updateMealTime(meal.id, newDateTime);
      
      // Очищаем кэш для текущей даты и перезагружаем данные
      final dateKey = _formatDateKey(_selectedDate);
      _mealsCache.remove(dateKey);
      _summaryCache.remove(dateKey);
      
      await _loadDataForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Время приёма пищи обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления времени: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Виджет для отображения данных питания
  Widget _buildNutritionContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              'Ошибка загрузки данных',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDataForDate(_selectedDate),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final meals = _getCachedMeals();
    final summary = _getCachedSummary();

    return RepaintBoundary(
      child: CustomScrollView(
        slivers: [
          // Сводка КБЖУ
          if (summary != null)
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: _buildSummaryCard(summary),
              ),
            ),
          
          // Список приемов пищи
          if (meals.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => RepaintBoundary(
                  child: _buildMealCard(meals[index]),
                ),
                childCount: meals.length,
              ),
            ),

          // Кнопка "добавить приём пищи"
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: _buildAddMealButton(),
            ),
          ),

          // Пустое состояние (если нет приёмов пищи)
          if (meals.isEmpty)
            SliverFillRemaining(
              child: RepaintBoundary(
                child: _buildEmptyState(),
              ),
            ),
        ],
      ),
    );
  }

  // Карточка сводки КБЖУ
  Widget _buildSummaryCard(DailySummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сводка за день',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientColumn('Калории', '${summary.totalCalories.toInt()}', 'ккал'),
              _buildNutrientColumn('Белки', '${summary.totalProteins.toInt()}', 'г'),
              _buildNutrientColumn('Жиры', '${summary.totalFats.toInt()}', 'г'),
              _buildNutrientColumn('Углеводы', '${summary.totalCarbs.toInt()}', 'г'),
            ],
          ),
        ],
      ),
    );
  }

  // Колонка с нутриентом
  Widget _buildNutrientColumn(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
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
          unit,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Карточка приема пищи
  Widget _buildMealCard(Meal meal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с временем и кнопками действий
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Время приёма пищи (кликабельное для редактирования)
              GestureDetector(
                onTap: () => _editMealTime(meal),
                child: Row(
                  children: [
                    Text(
                      meal.formattedTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              // Кнопка удаления
              IconButton(
                onPressed: () => _deleteMeal(meal),
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 20,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          
          if (meal.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            
            // Список блюд в приёме пищи
            ...meal.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Text('- ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      '${item.name} (${item.calories.toInt()} ккал / ${item.proteins.toInt()} б / ${item.fats.toInt()} ж / ${item.carbs.toInt()} у)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            
            const SizedBox(height: 8),
            
            // Разделитель
            Container(
              height: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(vertical: 4),
            ),
            
            const SizedBox(height: 8),
            
            // Итого по приёму пищи
            Text(
              '${meal.totalCalories.toInt()} ккал / ${meal.totalProteins.toInt()} б / ${meal.totalFats.toInt()} ж / ${meal.totalCarbs.toInt()} у',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Кнопка "добавить блюдо"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToDishSelection(meal.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Добавить блюдо',
                  style: TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Пустой приём пищи',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Кнопка "добавить блюдо" для пустого приёма пищи
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToDishSelection(meal.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Добавить блюдо',
                  style: TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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

  // Кнопка добавления нового приёма пищи
  Widget _buildAddMealButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _createNewMeal,
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Добавить приём пищи',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // Пустое состояние
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет данных о питании',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавьте приемы пищи для выбранной даты',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Питание'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Заголовок с навигацией по датам
          RepaintBoundary(
            child: DateNavigationHeader(
              selectedDate: _selectedDate,
              onPreviousDay: _goToPreviousDay,
              onNextDay: _goToNextDay,
              onDateTap: _selectDate,
            ),
          ),
          
          // Основное содержимое экрана
          Expanded(
            child: _buildNutritionContent(),
          ),
        ],
      ),
    );
  }
} 