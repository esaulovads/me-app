import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/date_navigation_header.dart';
import 'services/nutrition_service.dart';
import 'models/meal_model.dart';

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

  // Получение данных из кэша
  List<Meal> _getCachedMeals() {
    final dateKey = _formatDateKey(_selectedDate);
    return _mealsCache[dateKey] ?? [];
  }

  DailySummary? _getCachedSummary() {
    final dateKey = _formatDateKey(_selectedDate);
    return _summaryCache[dateKey];
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
            )
          else
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
          Text(
            meal.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Время: ${meal.formattedTime}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Калории: ${meal.calories.toInt()} ккал',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (meal.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Состав: ${meal.items.length} элемент${meal.items.length > 1 ? meal.items.length > 4 ? 'ов' : 'а' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
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